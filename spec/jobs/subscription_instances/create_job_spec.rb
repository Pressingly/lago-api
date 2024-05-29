require 'rails_helper'

RSpec.describe SubscriptionInstances::CreateJob, type: :job do
  let(:subscription) { create(:subscription) }

  let(:subscription_instance_service) { instance_double(SubscriptionInstances::CreateService) }
  let(:result) { BaseService::Result.new }

  it 'calls the subscription instance service' do
    allow(SubscriptionInstances::CreateService).to receive(:new)
      .with(subscription:)
      .and_return(subscription_instance_service)
    allow(subscription_instance_service).to receive(:call)
      .and_return(result)

    described_class.perform_now(subscription)

    expect(SubscriptionInstances::CreateService).to have_received(:new)
    expect(subscription_instance_service).to have_received(:call)
  end

  context 'when reccisult is a failure' do
    let(:result) do
      BaseService::Result.new.validation_failure!(errors: { subscription: ['is_not_active'] })
    end

    let(:subscription) { create(:subscription, :pending) }

    it 'raises an error' do
      allow(SubscriptionInstances::CreateService).to receive(:new)
        .with(subscription:)
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
