# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubscriptionInstances::IncreaseTotalValueService, type: :service do
  let(:subscription_instance) { create(:subscription_instance, total_amount: 1000, version_number: 1) }
  let(:service) { described_class.new(subscription_instance:, fee_amount: 500) }

  describe '#call' do
    context 'when the service is called successfully' do
      it 'increases the total subscription value' do
        result = service.call

        expect(result.subscription_instance.total_amount).to eq(1500)
        expect(result.subscription_instance.version_number).to eq(2)
      end
    end

    context 'when the update fails' do
      before do
        allow(subscription_instance).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(subscription_instance))
      end

      it 'does not increase the total subscription value' do
        result = service.call
        subscription_instance.reload

        expect(result.success?).to be(false)
        expect(subscription_instance.total_amount).to eq(1000)
      end
    end
  end
end
