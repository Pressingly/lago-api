# frozen_string_literal: true

class SubscriptionInstances::CreateJob < ApplicationJob
  queue_as 'billing'

  def perform(subscription)
    result = SubscriptionInstances::CreateService.new(subscription: subscription).call

    result.raise_if_error!
  end
end
