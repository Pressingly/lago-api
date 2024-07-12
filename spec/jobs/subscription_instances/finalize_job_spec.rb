# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubscriptionInstances::FinalizeJob, type: :job do
  describe '#perform' do
    let(:subscription_instance) { create(:subscription_instance) }
    let(:result) { BaseService::Result.new }

    before do
      allow(SubscriptionCharges::FinalizeService).to receive(:call).with(subscription_instance: subscription_instance)
    end

    it 'calls the finalize service with correct parameters' do
      described_class.perform_now(subscription_instance:)
      expect(SubscriptionCharges::FinalizeService).to have_received(:call).with(subscription_instance:)
    end
  end
end
