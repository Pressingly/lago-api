# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubscriptionInstances::IncreaseTotalValueService, type: :service do
  let(:initial_total_amount) { 100 }
  let(:fee_amount) { 50 }
  let(:subscription_instance) { create(:subscription_instance, total_amount: initial_total_amount, version_number: 1) }
  let(:service) { described_class.new(subscription_instance:, fee_amount:) }

  describe '#call' do
    context 'when the service is called successfully' do
      let(:thread_count) { 3 }

      it 'increases the total subscription value' do
        result = service.call

        expect(result.subscription_instance.total_amount).to eq(initial_total_amount + fee_amount)
        expect(result.subscription_instance.version_number).to eq(2)
      end

      it 'updates total_amount correctly with concurrent threads' do
        threads = Array.new(thread_count) do
          Thread.new do
            sleep(rand(0.1..0.5)) # Simulate some processing time
            described_class.new(subscription_instance: subscription_instance, fee_amount: fee_amount).call
          end
        end

        threads.each(&:join) # Wait for all threads to complete

        subscription_instance.reload

        expect(subscription_instance.total_amount).to eq(initial_total_amount + fee_amount * thread_count)
      end
    end
  end
end
