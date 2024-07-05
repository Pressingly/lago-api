# frozen_string_literal: true

module SubscriptionCharges
  class CreateService < BaseService
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
        amount: subscription_instance.total_amount.to_f,
        currencyCode: customer.currency,
        versionNumber: subscription_instance.version_number,
        description: plan.description,
        pinetIdToken: customer.pinet_id_token,
        subscriptionInstanceId: subscription_instance.id,
      }
      Rails.logger.info("Subcription charge creation payload: #{payload}")

      subscription_charge_result = stub.create_subscription_charge(Revenue::CreateSubscriptionChargeReq.new(payload))
      Rails.logger.info("Subcription charge creation subscription_charge_result: #{subscription_charge_result}")

      subscription_instance.pinet_subscription_charge_id = subscription_charge_result.subscriptionChargeId
      subscription_instance.save!
    rescue GRPC::BadStatus => e
      result.service_failure!(code: 'grpc_failed', message: "updating subscription charge: #{e.message}")
    end
  end
end
