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
      payload = {
        subscriptionChargeId: subscription_instance.pinet_subscription_charge_id,
        versionNumber: subscription_instance.version_number,
        amount: subscription_instance.total_amount.to_f,
        pinetIdToken: customer.pinet_id_token,
        currencyCode: customer.currency,
        description: plan(subscription_instance).description,
      }

      Rails.logger.info("Subcription charge update payload: #{payload}")

      stub.update_subscription_charge(Revenue::UpdateSubscriptionChargeReq.new(payload))
    rescue GRPC::BadStatus => e
      raise StandardError, "Error updating subscription charge: #{e.message}"
    end
  end
end
