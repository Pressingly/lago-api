# frozen_string_literal: true

module SubscriptionInstances
  class TransitionJob < ApplicationJob
    queue_as 'billing'

    def perform(subscription:, timestamp:)
      return unless subscription.active?

      boundaries = date_service(subscription, timestamp)
      result = SubscriptionInstances::CreateService.new(
        subscription:,
        started_at: boundaries.from_datetime,
        ended_at: boundaries.to_datetime
      ).call

      result.raise_if_error!

      if result.subscription_instance.present? && result.subscription_instance_item.present?
        SubscriptionCharges::CreateService.call(
          subscription_instance: result.subscription_instance,
          subscription_instance_item: result.subscription_instance_item
        )
      end
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
