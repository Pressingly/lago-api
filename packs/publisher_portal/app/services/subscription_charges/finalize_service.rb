# frozen_string_literal: true

module SubscriptionCharges
  class FinalizeService < BaseService
    include ServiceHelper

    def initialize(subscription_instance:)
      @subscription_instance = subscription_instance

      super
    end

    def call
      customer = subscription_instance.subscription.customer
      plan = subscription_instance.subscription.plan
      payload = {
        subscriptionChargeId: subscription_instance.pinet_subscription_charge_id,
        versionNumber: subscription_instance.version_number,
        amount: subscription_instance.total_amount.to_f,
        currencyCode: customer.currency,
        description: plan.description,
        pinetIdToken: customer.pinet_id_token,
      }

      Rails.logger.info("Subcription charge finalization payload: #{payload}")
      stub.finalize_subscription_charge(Revenue::FinalizeSubscriptionChargeReq.new(payload))

      result
    rescue GRPC::BadStatus => e
      result.service_failure!(code: 'grpc_failed', message: "finalize subscription charge: #{e.message}")
    end

    private

    attr_reader :subscription_instance
  end
end
