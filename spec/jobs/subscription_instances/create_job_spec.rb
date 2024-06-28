# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubscriptionInstances::CreateJob, type: :job do
  let(:subscription) { create(:subscription) }
  let(:subscription_instance) { create(:subscription_instance, subscription: subscription) }

  let(:subscription_instance_service) { instance_double(SubscriptionInstances::CreateService) }
  let(:result) { BaseService::Result.new }

  context 'when result is a success' do
    before do
      result
      result.subscription_instance = subscription_instance
    end

    it 'calls the subscription instance service' do
      allow(SubscriptionInstances::CreateService).to receive(:new)
        .and_return(subscription_instance_service)
      allow(subscription_instance_service).to receive(:call)
        .and_return(result)

      described_class.perform_now(subscription)

      expect(SubscriptionInstances::CreateService).to have_received(:new)
      expect(subscription_instance_service).to have_received(:call)
    end
  end

  context 'when result is a failure' do
    before do
      result
      result.subscription_instance = subscription_instance
    end

    let(:result) do
      BaseService::Result.new.validation_failure!(errors: { subscription: ['is_not_active'] })
    end

    let(:subscription) { create(:subscription, :pending) }

    it 'raises an error' do
      allow(SubscriptionInstances::CreateService).to receive(:new)
        .and_return(subscription_instance_service)
      allow(subscription_instance_service).to receive(:call)
        .and_return(result)

      expect do
        described_class.perform_now(subscription)
      end.to raise_error(BaseService::FailedResult)

      expect(SubscriptionInstances::CreateService).to have_received(:new)
      expect(subscription_instance_service).to have_received(:call)
    end
  end
end
