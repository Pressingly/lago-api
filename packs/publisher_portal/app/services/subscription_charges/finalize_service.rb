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
        amount: subscription_instance.total_amount.to_f,
        currencyCode: customer.currency,
        description: plan.description,
        pinetIdToken: customer.pinet_id_token,
      }

      Rails.logger.info("Subcription charge finalization payload: #{payload}")
      finalize_result = stub.finalize_subscription_charge(Revenue::FinalizeSubscriptionChargeReq.new(payload))

      if finalize_result&.status == :SUBSCRIPTION_CHARGE_CONTRACT_STATUS_APPROVED
        subscription_instance.finalize!
      end

      Rails.logger.info("Subcription charge finalization result: #{finalize_result}")

      result
    rescue GRPC::BadStatus => e
      result.service_failure!(code: 'grpc_failed', message: "finalize subscription charge: #{e.message}")
    end

    private

    attr_reader :subscription_instance
  end
end
