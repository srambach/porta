# frozen_string_literal: true

class Finance::Api::PaymentCallbacks::StripeCallbacksController < Finance::Api::BaseController
  before_action :ensure_stripe_payment_gateway

  class StripeCallbackError < StandardError; end
  class InvalidStripeEvent < StripeCallbackError; end

  # Undocumented endpoint used for update callbacks of async-authorized payment transactions (mostly due to SCA regulations)
  def create
    sig_header = request.headers['Stripe-Signature']
    endpoint_secret = 'whsec_6LXKKvZM3Sbf4gv5dHoZ7WTXB08vp14N' # TODO: fetch from provider's payment gateway settings

    stripe_event = Stripe::Webhook.construct_event(request.raw_post, sig_header, endpoint_secret)
    payment_intent_data = case stripe_event.type # Also checked by PaymentIntent#confirm_stripe_payment_intent, but here it can save us some processing and ensure an immediate response at the level of the controller in case of unsupported event types
                          when 'payment_intent.succeeded'
                            stripe_event.data.object
                          else
                            raise InvalidStripeEvent
                          end

    payment_intent = PaymentIntent.by_invoice(current_account.buyer_invoices).find_by!(payment_intent_id: payment_intent_data['id'])

    unless payment_intent.confirm_stripe_payment_intent(stripe_event)
      exception = StripeCallbackError.new('Cannot update Stripe payment intent')
      System::ErrorReporting.report_error(exception, event: stripe_event, payment_intent: payment_intent)
    end

    head :ok
  rescue JSON::ParserError, InvalidStripeEvent
    render_error(:not_found, status: :not_found)
  rescue Stripe::SignatureVerificationError
    render_error('Signature verification failed', status: :bad_request)
  end

  protected

  def ensure_stripe_payment_gateway
    return if current_account.payment_gateway_type == :stripe
    render_error(:not_found, status: :not_found)
    false
  end
end
