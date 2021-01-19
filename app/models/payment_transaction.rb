class ::ActiveMerchant::Billing::AuthorizeNetGateway
  def cim_gateway
    @cim_gateway ||=  ::ActiveMerchant::Billing::AuthorizeNetCimGateway.new(options)
  end
end

class PaymentTransaction < ApplicationRecord
  include Symbolize
  belongs_to :account
  belongs_to :invoice, inverse_of: :payment_transactions

  symbolize :action
  serialize :params
  has_money :amount

  validates :amount, presence: true
  validates :currency, length: {maximum: 4}
  validates :message, :reference, :action, length: {maximum: 255}

  attr_protected :account_id, :invoice_id, :success, :test, :tenant_id

  scope :failed, -> { where(:success => false) }
  scope :succeeded, -> { where(:success => true) }
  scope :oldest_first, -> { order(:created_at) }

  def process!(credit_card_auth_code, gateway, gateway_options)
    if System::Application.config.three_scale.payments.enabled
      gateway_options[:currency] = currency

      logger.info("Processing PaymentTransaction with code #{credit_card_auth_code}, gateway #{gateway} & options #{gateway_options}")

      begin
        logger.info("Purchasing with #{gateway.class}")
        response = case gateway
                   when ActiveMerchant::Billing::AuthorizeNetGateway
          purchase_with_authorize_net(credit_card_auth_code, gateway)
                   when ActiveMerchant::Billing::StripePaymentIntentsGateway
          purchase_with_stripe(credit_card_auth_code, gateway, gateway_options.reverse_merge(off_session: true, execute_threed: true))
                   when ActiveMerchant::Billing::StripeGateway
          purchase_with_stripe(credit_card_auth_code, gateway, gateway_options)
                   else
          gateway.purchase(amount.cents, credit_card_auth_code, gateway_options)
        end

        self.success = response.success?
        self.reference = response.authorization
        self.message = response.message
        self.params = response.params
        self.test = response.test
      rescue ActiveMerchant::ActiveMerchantError => exception
        logger.info("Processing of PaymentTransaction threw an exception: #{exception.message}")
        self.success = false
        self.message = exception.message
        self.test = gateway.test?
        raise exception
      ensure
        logger.info("Saving PaymentTransaction")
        self.save!
      end

      unless response && response.success?
        logger.info("PaymentTransaction processing not successful. Response: #{response.inspect}")
        raise Finance::Payment::CreditCardPurchaseFailed.new(response)
      end

      self
    else
      logger.info "Skipping payment transaction #process! - not in production"
      return
    end
  end

  # TODO: writable currency should be feature of the has_money plugin.
  # XXX: has_money plugin is a ghetoo
  module AmountWithCurrency
    def amount=(value)
      if value.respond_to?(:currency)
        super(value.amount)
        self.currency = value.currency
      else
        super(value)
      end
    end
  end
  prepend AmountWithCurrency


  def self.to_xml(payment_transactions, options = {})
    builder = ThreeScale::XML::Builder.new

    builder.payment_transactions do |xml|
      payment_transactions.each{ |pt| pt.to_xml(:builder => xml) }
    end

    builder.to_xml
  end

  def to_xml(options = {})
    xml = options[:builder] || ThreeScale::XML::Builder.new

    xml.payment_transaction do |xml|
      unless new_record?
        xml.id_ id
        xml.created_at created_at.xmlschema
        xml.updated_at updated_at.xmlschema
      end

      xml.invoice_id invoice_id
      xml.account_id account_id
      xml.reference reference
      xml.success success
      xml.amount amount
      xml.currency currency
      xml.action action
      xml.message message
      if params
        params.to_xml(root: 'gateway_response', builder: xml, skip_instruct: true, dasherize: false)
      else
        xml.gateway_response nil
      end
      xml.test test
    end

    xml.to_xml
  end

  private

  def purchase_with_authorize_net(credit_card_auth_code, gateway)
    profile_response = get_profile_response(credit_card_auth_code, gateway)
    if profile_response.success?
      payment_profiles = profile_response.params['profile']['payment_profiles']

      # BEWARE: payment_profiles could be a Hash or an Array
      payment_profile = payment_profiles.is_a?(Array) ? payment_profiles[-1] : payment_profiles
      payment_profile_id = payment_profile['customer_payment_profile_id']

      gateway.cim_gateway
        .create_customer_profile_transaction(:transaction => {
        :customer_profile_id => credit_card_auth_code,
        :customer_payment_profile_id => payment_profile_id,
        :type => :auth_capture,
        # BEWARE - THIS MUST NOT BE CENTS - Charging mess up from March 5,  2013
        :amount => amount.to_f })
    # gateway.cim_gateway.commit('AUTH_CAPTURE', money, post)
    else
      profile_response
    end
  end

  def get_profile_response(credit_card_auth_code, gateway)
    gateway.cim_gateway.get_customer_profile(:customer_profile_id => credit_card_auth_code)
  end

  # TODO: Move all methods below to another class

  delegate :latest_pending_payment_intent, to: :invoice, allow_nil: true

  def purchase_with_stripe(credit_card_auth_code, gateway, gateway_options)
    options = gateway_options.merge(customer: credit_card_auth_code)
    payment_method_id = options.delete(:payment_method_id)

    if (payment_intent = latest_pending_payment_intent)
      confirm_payment_intent_with_stripe(gateway, payment_method_id, payment_intent, options)
    else
      create_payment_intent_with_stripe(gateway, payment_method_id, amount, options)
    end
  end

  def create_payment_intent_with_stripe(gateway, payment_method_id, amount, options)
    response = gateway.purchase(amount.cents, payment_method_id, options)

    ensure_stripe_payment_intent(response) do |payment_intent_data|
      next unless invoice
      payment_intent = invoice.payment_intents.create!(payment_intent_id: payment_intent_data['id'], state: payment_intent_data['status'])

      # Tries to confirm the payment intent according to status, but still returns the response of the create attempt
      #
      # PaymentIntent return statuses:
      # - succeeded                => no additional action > payment has succeeded
      # - requires_confirmation    => confirm the payment intent
      # - requires_action          => check `payment_intent_data['next_action']` for instructions
      # - requires_payment_method  => do not retry > payment attempt has failed > ask cardholder to replace card data
      # Source: https://stripe.com/docs/payments/accept-a-payment-synchronously
      confirm_payment_intent_with_stripe(gateway, payment_method_id, payment_intent, options) if payment_intent.state == 'requires_confirmation'
    end
  end

  def confirm_payment_intent_with_stripe(gateway, payment_method_id, payment_intent, options)
    # `off_session: false` is probably NOT the right Stripe flow for us, but it provokes a `requires_action` response where otherwise it would be `requires_payment_method`
    # With `requires_action`, we can then use: params.dig('next_action', 'use_stripe_sdk', 'stripe_js')
    response = gateway.confirm_intent(payment_intent.payment_intent_id, payment_method_id, options.merge(off_session: false))

    ensure_stripe_payment_intent(response) do |payment_intent_data|
      payment_intent_status = payment_intent_data['status']
      payment_intent.update!(state: payment_intent_status)

      next if payment_intent_status == 'succeeded'

      # Because Stripe won't wrap the response into an 'error' thus making ActiveMerchant to think it's a success.
      # See https://github.com/activemerchant/active_merchant/blob/b2f5e89eb383429d47e446f248d7bfe4f95ac3d0/lib/active_merchant/billing/gateways/stripe.rb#L690
      response.instance_variable_set(:@success, false)
      response.instance_variable_set(:@message, payment_intent_status.humanize)
    end
  end

  def ensure_stripe_payment_intent(response)
    payment_intent_data = extract_stripe_payment_intent_data(response)
    yield(payment_intent_data) if payment_intent_data.present?
    response
  end

  def extract_stripe_payment_intent_data(response)
    response_params = response.params
    return response_params if response.success?
    response_params.dig('error', 'payment_intent')
  end
end
