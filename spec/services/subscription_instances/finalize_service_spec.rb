# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubscriptionInstances::FinalizeService, type: :service do
  describe '#call' do
    context 'with valid parameters' do
      let(:subscription_instance) { create(:subscription_instance, total_amount: 0.0) }
      let(:subscription_fee) { create(:fee, fee_type: 'subscription') }
      let(:charges_fees) { [create(:charge_fee)] }

      it 'finalize the subscription instance and calculate total amount correctly' do
        result = described_class.new(
          subscription_instance: subscription_instance,
          subscription_fee: subscription_fee,
          charges_fees: charges_fees
        ).call

        expect(result.subscription_instance.status).to eq('finalized')
        total_amount = charges_fees.sum(&:amount_cents).fdiv(charges_fees.last.amount.currency.subunit_to_unit)
        total_amount += subscription_fee.amount_cents.fdiv(subscription_fee.amount.currency.subunit_to_unit)

        expect(result.subscription_instance.total_amount).to eq(total_amount)
      end
    end

    context 'when subscription fee is not present' do
      let(:subscription_instance) { create(:subscription_instance) }
      let(:charges_fees) { [create(:charge_fee)] }

      it 'does not create subscription instance items for charges fees' do
        result = described_class.new(
          subscription_instance: subscription_instance,
          subscription_fee: nil,
          charges_fees: charges_fees
        ).call

        expect(result.success?).to eq(true)
        expect(result.subscription_instance.status).to eq('finalized')
        total_amount = charges_fees.sum(&:amount_cents).fdiv(charges_fees.last.amount.currency.subunit_to_unit)

        expect(result.subscription_instance.total_amount).to eq(total_amount)
      end
    end

    context 'when charges fess are blank' do
      let(:subscription_instance) { create(:subscription_instance) }
      let(:subscription_fee) { create(:fee, fee_type: 'subscription') }

      it 'does not create subscription instance items for charges fees' do
        result = described_class.new(
          subscription_instance: subscription_instance,
          subscription_fee: subscription_fee,
          charges_fees: nil
        ).call

        expect(result.success?).to eq(true)
        expect(result.subscription_instance.status).to eq('finalized')
        total_amount = subscription_fee.amount_cents.fdiv(subscription_fee.amount.currency.subunit_to_unit)

        expect(result.subscription_instance.total_amount).to eq(total_amount)
      end
    end
  end
end
