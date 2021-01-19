# frozen_string_literal: true

class PaymentIntent < ApplicationRecord
  belongs_to :invoice, inverse_of: :payment_intents

  validates :invoice, :payment_intent_id, :state, presence: true
  validates :payment_intent_id, :state, length: { maximum: 255 }

  scope :latest, -> (count = 1) { reorder(created_at: :desc).limit(count) }
  scope :latest_pending, ->() { where.not(state: :succeeded).latest }

  scope :by_invoice, ->(invoice_ids) { where(invoice: invoice_ids) }

  def confirm_stripe_payment_intent(event)
    return unless event.type == 'payment_intent.succeeded'

    payment_intent_data = event.data.object

    transaction do
      self.state = payment_intent_data['status']

      payment_transaction = invoice.payment_transactions.build({
        action: :purchase,
        amount: payment_intent_data['amount'].to_has_money(payment_intent_data['currency']&.upcase || invoice.currency) / 100.0,
        success: true,
        message: 'Payment confirmed',
        reference: payment_intent_data['id'],
        params: event.to_hash
      }, without_protection: true)

      save && payment_transaction.save && invoice.pay
    end
  end
end
