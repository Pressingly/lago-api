# frozen_string_literal: true

module SubscriptionCharges
  class UpdateService < BaseService
    include ServiceHelper

    def initialize(subscription_instance:)
      @subscription_instance = subscription_instance
    end

    attr_reader :subscription_instance

    def call
      customer = subscription_instance.subscription.customer
      stub.update_subscription_charge(Revenue::UpinetIdTokenpdateSubscriptionChargeReq.new(
        {
          subscriptionChargeId: subscription_instance.pinet_subscription_charge_id,
          versionNumber: subscription_instance.version_number,
          amount: subscription_instance.total_amount.to_f,
          currencyCode: customer.currency,
          description: plan(subscription_instance).description,
        }
      ))
    rescue GRPC::BadStatus => e
      raise StandardError, "Error updating subscription charge: #{e.message}"
    end
  end
end
