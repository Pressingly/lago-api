# frozen_string_literal: true

module SubscriptionCharges
  class FinalizeService < BaseService
    include ServiceHelper

    def initialize(subscription_instance:)
      @subscription_instance = subscription_instance

      super
    end

    attr_reader :subscription_instance

    def call
      customer = subscription_instance.subscription.customer
      plan = subscription_instance.subscription.plan
      payload = {
        subscriptionChargeId: subscription_instance.pinet_subscription_charge_id,
        versionNumber: subscription_instance.version_number,
        amount: subscription_instance.total_amount.to_f,
        currencyCode: customer.currency,
        description: plan.description,
      }

      stub.finalize_subscription_charge(Revenue::FinalizeSubscriptionChargeReq.new(payload))
      Rails.logger.info("Subcription charge finalization payload: #{payload}")
    rescue GRPC::BadStatus => e
      result.service_failure!(code: 'grpc_failed', error_message: "finalize subscription charge: #{e.message}")
    end
  end
end
