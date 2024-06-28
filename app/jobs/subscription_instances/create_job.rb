# frozen_string_literal: true

class SubscriptionInstances::CreateJob < ApplicationJob
  queue_as 'billing'

  def perform(subscription)
    boundaries = date_service(subscription)
    result = SubscriptionInstances::CreateService.new(
      subscription:,
      started_at: boundaries.from_datetime,
      ended_at: boundaries.to_datetime
    ).call

    result.raise_if_error!

    if result.subscription_instance.total_amount.positive?
      SubscriptionCharges::CreateService.call(subscription_instance: result.subscription_instance)
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
