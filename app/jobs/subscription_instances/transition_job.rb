# frozen_string_literal: true

module SubscriptionInstances
  class TransitionJob < ApplicationJob
    include SubscriptionInstances::Helper
    queue_as 'billing'

    def perform(subscription:, timestamp:)
      boundaries = date_service(subscription, timestamp)
      result = SubscriptionInstances::CreateService.new(
        subscription:,
        started_at: boundaries.from_datetime,
        ended_at: boundaries.to_datetime
      ).call

      result.raise_if_error!

      if should_subscription_charge?(result)
        SubscriptionCharges::CreateService.call(
          subscripton_instance: result.subscription_instance,
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

    def should_subscription_charge?(result)
      subscription_instance = result.subscription_instance
      subscription_instance_item = result.subscription_instance_item

      subscription_instance.present? &&
        subscription_instance_item.present? &&
        subscription_instance_item.charge_type == SubscriptionInstanceItem.charge_types[:base_charge] &&
        subscription_instance_item.fee_amount.positive?
    end
  end
end
