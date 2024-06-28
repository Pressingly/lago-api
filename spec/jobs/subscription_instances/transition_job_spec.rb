# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubscriptionInstances::TransitionJob, type: :job do
  describe '#perform' do
    let(:subscription) { create(:subscription) }
    let(:timestamp) { Time.current }
    let(:boundaries) { OpenStruct.new(from_datetime: Time.current.beginning_of_day, to_datetime: Time.current.end_of_day) }
    let(:create_service) { instance_double(SubscriptionInstances::CreateService) }

    before do
      allow(Subscriptions::DatesService).to receive(:new_instance).with(subscription, timestamp, current_usage: true).and_return(boundaries)
      allow(SubscriptionInstances::CreateService).to receive(:new).with(
        subscription: subscription,
        started_at: boundaries.from_datetime,
        ended_at: boundaries.to_datetime
      ).and_return(create_service)

      allow(create_service).to receive(:call).and_return(BaseService::Result.new)
    end

    it 'calls the create service with correct parameters' do
      described_class.perform_now(subscription: subscription, timestamp: timestamp)

      expect(Subscriptions::DatesService).to have_received(:new_instance).with(subscription, timestamp, current_usage: true)
      expect(SubscriptionInstances::CreateService).to have_received(:new).with(
        subscription: subscription,
        started_at: boundaries.from_datetime,
        ended_at: boundaries.to_datetime
      )
      expect(create_service).to have_received(:call)
    end
  end
end
