# frozen_string_literal: true

class SubscriptionInstances::CreateJob < ApplicationJob
  queue_as 'billing'

  def perform(subscription)
    ActiveRecord::Base.transaction do
      result = SubscriptionInstances::CreateService.new(subscription: subscription).call

      # SubscriptionCharges::CreateService.call(subscription: subscription) if result.subscription_instance.total_amount > 0

      result.raise_if_error!
    end
  end
end
