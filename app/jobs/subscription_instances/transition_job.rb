# frozen_string_literal: true

module SubscriptionInstances
  class TransitionJob < ApplicationJob
    queue_as 'billing'

    def perform(subscription:, timestamp:)
      boundaries = date_service(subscription, timestamp)
      result = SubscriptionInstances::CreateService.new(
        subscription:,
        started_at: boundaries.from_datetime,
        ended_at: boundaries.to_datetime
      ).call

      result.raise_if_error!
    end

    private

    def date_service(subscription, timestamp)
      Subscriptions::DatesService.new_instance(
        subscription,
        timestamp,
        current_usage: true
      )
    end
  end
end
