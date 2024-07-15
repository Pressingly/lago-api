# frozen_string_literal: true

module SubscriptionInstances
  class FinalizeJob < ApplicationJob
    queue_as 'billing'

    def perform(subscription_instance:)
      ActiveRecord::Base.transaction do
        SubscriptionCharges::FinalizeService.call(subscription_instance:)
      end
    end
  end
end
