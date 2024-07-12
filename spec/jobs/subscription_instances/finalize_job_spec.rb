# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubscriptionInstances::FinalizeJob, type: :job do
  describe '#perform' do
    let(:subscription_instance) { create(:subscription_instance) }
    let(:result) { BaseService::Result.new }

    it 'calls the finalize service with correct parameters' do
      described_class.perform_now(subscription_instance:)
      expect(finalize_service).to have_received(:call)
    end
  end
end
