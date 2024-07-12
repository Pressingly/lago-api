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
        description: plan.description,
        pinetIdToken: customer.pinet_id_token,
        subscriptionInstanceId: subscription_instance.id,
        subscriptionInstanceItemId: subscription_instance_item.id,
      }

      subscription_charge_result = stub.create_subscription_charge(Revenue::CreateSubscriptionChargeReq.new(payload))
      # TODO: update with actual response from gRPC
      if subscription_charge_result&.status == "approved"
        subscription_instance_item.approve!
        update_subscription_instance_total_amount(subscription_instance_item.fee_amount)
      elsif subscription_charge_result&.status == "rejected"
        subscription_instance_item.reject!
      end

      Rails.logger.info("Subcription charge creation payload: #{payload}")

      subscription_charge_result = stub.create_subscription_charge(Revenue::CreateSubscriptionChargeReq.new(payload))
      Rails.logger.info("Create subscription charge result: #{subscription_charge_result}")

      subscription_instance.pinet_subscription_charge_id = subscription_charge_result.subscriptionChargeId
      subscription_instance.save!
    rescue GRPC::BadStatus => e
      result.service_failure!(code: 'grpc_failed', message: "updating subscription charge: #{e.message}")
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
