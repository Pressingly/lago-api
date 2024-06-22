# frozen_string_literal: true

module SubscriptionCharges
  class UpdateService < BaseService
    include ServiceHelper

    def initialize(subscription_instance:)
      @subscription_instance = subscription_instance
    end

    attr_reader :subscription_instance

    def call
      stub.update_subscription_charge(Revenue::UpdateSubscriptionChargeReq.new(
        {
          amount: subscription_instance.total_amount.to_f,
          version_number: subscription_instance.version_number,
          description: plan(subscription_instance).description,
          subscriptionChargeId: subscription_instance.pinet_subscription_charge_id,
        }
      ))
    rescue GRPC::BadStatus => e
      raise StandardError, "Error updating subscription charge: #{e.message}"
    end
  end
end
