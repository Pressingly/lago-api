# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubscriptionInstances::CreateService, type: :service do
  subject(:create_service) { described_class.new(subscription:, started_at: subscription.started_at, ended_at:) }

  let(:amount_cents) { 100 }
  let(:subscription) { create(:subscription, plan:) }
  let(:plan) { create(:plan, interval: 'weekly', pay_in_advance: true, amount_cents:) }
  let(:ended_at) { subscription.started_at + 6.days }

  describe '#call' do
    context 'when the subscription is valid' do
      it 'create a subscription instance and a corresponding subscription instance item' do
        result = create_service.call

        aggregate_failures do
          expect(result).to be_success
          currency = plan.amount.currency
          fee_amount = plan.amount_cents.fdiv(currency.subunit_to_unit)

          subscription_instance = result.subscription_instance
          expect(subscription_instance.started_at.to_i).to eq(subscription.started_at.to_i)
          expect(subscription_instance.ended_at.to_i).to eq(ended_at.to_i)

          subscription_instance_items = subscription_instance.subscription_instance_items
          expect(subscription_instance_items.count).to eq(1)

          expect(subscription_instance_items.first.fee_amount).to eq(fee_amount)
          expect(subscription_instance.total_amount).to eq(0)
        end
      end
    end

    context 'when the subscription is not active' do
      let(:subscription) { create(:subscription, :pending) }

      it 'returns an error' do
        result = create_service.call

        aggregate_failures do
          expect(result).not_to be_success
          expect(result.error).to be_a(BaseService::ValidationFailure)
          expect(result.error.messages[:subscription]).to eq(['is_not_active'])
        end
      end
    end
  end
end
