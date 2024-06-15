# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubscriptionInstanceItems::CreateService do
  let(:subscription_instance) { create(:subscription_instance) }
  let(:fee_amount) { 1000 }
  let(:charge_type) { 'base_charge' }
  let(:code) { nil }
  let(:service) { described_class.new(subscription_instance:, fee_amount:, charge_type:, code:) }

  describe '#call' do
    context 'with valid parameters' do
      it 'returns a result with the created SubscriptionInstanceItem' do
        result = service.call
        expect(result.subscription_instance_item).to be_a(SubscriptionInstanceItem)
        expect(result.subscription_instance_item.charge_type).to eq(charge_type)
        expect(result.subscription_instance_item.fee_amount).to eq(fee_amount)
      end
    end

    context 'when charge_type is usage_charge' do
      let(:charge_type) { 'usage_charge' }
      let(:code) { 'valid_code' }

      it 'is valid with a code' do
        result = service.call
        expect(result.subscription_instance_item.code).to eq(code)
      end

      context 'without a code' do
        let(:code) { nil }

        it 'returns error' do
          result = service.call

          aggregate_failures do
            expect(result).not_to be_success
            expect(result.error).to be_a(BaseService::ValidationFailure)
            expect(result.error.messages[:code]).to eq(['value_is_mandatory'])
          end
        end
      end
    end

    context 'with invalid charge type' do
      let(:charge_type) { 'invalid_charge_type' }

      it 'returns error' do
        result = service.call

        aggregate_failures do
          expect(result).not_to be_success
          expect(result.error).to be_a(BaseService::ValidationFailure)
          expect(result.error.messages[:charge_type]).to eq(['invalid_charge_type'])
        end
      end
    end
  end
end
