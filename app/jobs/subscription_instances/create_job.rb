# frozen_string_literal: true

class SubscriptionInstances::CreateJob < ApplicationJob
  queue_as 'billing'

  def perform(subscription)
    result = SubscriptionInstances::CreateService.new(subscription: subscription).call

    # only create sub charges when total_amount is greater than 0

    SubscriptionCharges::CreateService.call(subscription: subscription) if result.subscription_instance.total_amount > 0

    result.raise_if_error!
  end
end
