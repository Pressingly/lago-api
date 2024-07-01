# frozen_string_literal: true

class SubscriptionInstances::CreateJob < ApplicationJob
  include SubscriptionInstances::Helper
  queue_as 'billing'

  def perform(subscription)
    boundaries = date_service(subscription)
    ActiveRecord::Base.transaction do
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
  end

  private

  def date_service(subscription)
    Subscriptions::DatesService.new_instance(
      subscription,
      subscription.started_at,
      current_usage: true
    )
  end
end
