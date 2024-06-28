# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Events::Sync::CreateSyncService, type: :service do
  subject(:create_sync_service) do
    described_class.new(
      organization:,
      params: create_args,
      timestamp: creation_timestamp,
      metadata:,
    )
  end

  let(:organization) { create(:organization) }

  let(:code) { 'sum_agg' }
  let(:external_customer_id) { SecureRandom.uuid }
  let(:external_subscription_id) { SecureRandom.uuid }
  let(:timestamp) { Time.current.to_f }
  let(:transaction_id) { SecureRandom.uuid }

  let(:creation_timestamp) { Time.current.to_f }

  let(:create_args) do
    {
      external_customer_id:,
      external_subscription_id:,
      code:,
      transaction_id:,
      properties: { foo: 'bar' },
      timestamp:,
    }
  end

  let(:metadata) { {} }

  describe '#call' do
    it 'creates an event' do
      result = nil

      aggregate_failures do
        expect { result = create_sync_service.call }.to change(Event, :count).by(1)

        expect(result).to be_success
        expect(result.event).to have_attributes(
          external_customer_id:,
          external_subscription_id:,
          transaction_id:,
          code:,
          timestamp: Time.zone.at(timestamp),
          properties: { 'foo' => 'bar' },
        )
      end
    end

    it 'performs post process job immediately' do
      allow(Events::PostProcessJob).to receive(:perform_now)

      create_sync_service.call

      expect(Events::PostProcessJob).to have_received(:perform_now).with(event: instance_of(Event))
    end
  end
end
