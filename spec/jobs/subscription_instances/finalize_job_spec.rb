# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubscriptionInstances::FinalizeJob, type: :job do
  describe '#perform' do
    let(:subscription_instance) { create(:subscription_instance) }
    let(:result) { BaseService::Result.new }
    let(:subscription_fee) { create(:fee, fee_type: 'subscription') }
    let(:charge_fee) { create(:charge_fee) }
    let(:charges_fees) { [charge_fee] }

    it 'calls the finalize service with correct parameters' do
      described_class.perform_now(subscription_instance:, subscription_fee:, charges_fees:)
      expect(finalize_service).to have_received(:call)
    end
  end
end
