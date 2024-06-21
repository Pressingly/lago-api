# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubscriptionInstances::FinalizeJob, type: :job do
  describe '#perform' do
    let(:subscription_instance) { create(:subscription_instance) }
    let(:finalize_service) { instance_double(SubscriptionInstances::FinalizeService) }
    let(:result) { BaseService::Result.new }
    let(:subscription_fee) { create(:fee, fee_type: 'subscription') }
    let(:charge_fee) { create(:charge_fee) }
    let(:charges_fees) { [charge_fee] }

    before do
      allow(SubscriptionInstances::FinalizeService).to receive(:new)
        .with(
          subscription_instance: subscription_instance,
          subscription_fee: subscription_fee,
          charges_fees: charges_fees
        ).and_return(finalize_service)

      allow(finalize_service).to receive(:call).and_return(result)
    end

    it 'calls the finalize service with correct parameters' do
      described_class.perform_now(subscription_instance:, subscription_fee:, charges_fees:)
      expect(SubscriptionInstances::FinalizeService).to have_received(:new).with(
        subscription_instance: subscription_instance,
        subscription_fee: subscription_fee,
        charges_fees: charges_fees
      )

      expect(finalize_service).to have_received(:call)
    end
  end
end
