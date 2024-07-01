# frozen_string_literal: true

module SubscriptionCharges
  class CreateService < BaseService
    include ServiceHelper

    def initialize(subscription_instance:, subscription_instance_item:)
      @subscription_instance = subscription_instance
      @subscription_instance_item = subscription_instance_item

      super
    end

    attr_reader :subscription_instance, :subscription_instance_item

    def call
      customer = subscription_instance.subscription.customer
      plan = subscription_instance.subscription.plan
      payload = {
        amount: subscription_instance_item.fee_amount.to_f,
        currencyCode: customer.currency,
        versionNumber: subscription_instance.version_number,
        description: plan.description,
        pinetIdToken: customer.pinet_id_token,
        subscriptionInstanceId: subscription_instance.id,
      }

      subscription_charge_result = stub.create_subscription_charge(Revenue::CreateSubscriptionChargeReq.new(payload))

      # TODO: check response status
      if subscription_charge_result["status"] == "approved"
        subscription_instance_item.approve!
        update_subscription_instance_total_amount(subscription_instance_item.fee_amount)
      elsif subscription_charge_result["status"] == "rejected"
        subscription_instance_item.reject!
      end

      Rails.logger.info("Subcription charge creation payload: #{payload}")
    rescue GRPC::BadStatus => e
      result.service_failure!(code: 'grpc_failed', error_message: "updating subscription charge: #{e.message}")
    end

    private

    def update_subscription_instance_total_amount(fee_amount)
      return unless fee_amount.positive?

      SubscriptionInstances::IncreaseTotalValueService.call(
        subscription_instance:,
        fee_amount:
      ).raise_if_error!
    end
  end
end
