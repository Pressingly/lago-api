# frozen_string_literal: true

class SubscriptionInstances::CreateJob < ApplicationJob
  queue_as 'billing'

  def perform(subscription)
    ActiveRecord::Base.transaction do
      result = SubscriptionInstances::CreateService.new(subscription: subscription).call

      if result.subscription_instance.total_amount.positive?
        SubscriptionCharges::CreateService.call(subscription_instance: result.subscription_instance)
      end

      result.raise_if_error!
    end
  end
end
