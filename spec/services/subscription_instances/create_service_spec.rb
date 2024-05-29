# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubscriptionInstances::CreateService, type: :service do
  subject(:create_service) { described_class.new(subscription:) }

  let(:subscription) { create(:subscription, plan:) }
  let(:plan) { create(:plan, interval: 'weekly') }

  describe '#call' do
    context 'when the subscription is valid' do
      it 'create a subscription instance' do
        result = create_service.call

        aggregate_failures do
          expect(result).to be_success

          subscription_instance = result.subscription_instance
          expect(subscription_instance.started_at).to eq(subscription.started_at)
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
