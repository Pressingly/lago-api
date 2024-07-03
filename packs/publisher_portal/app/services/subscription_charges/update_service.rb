# frozen_string_literal: true

module SubscriptionCharges
  class UpdateService < BaseService
    include ServiceHelper

    def initialize(subscription_instance:, subscription_instance_item:)
      @subscription_instance = subscription_instance
      @subscription_instance_item = subscription_instance_item
    end

    attr_reader :subscription_instance, :subscription_instance_item

    def call
      update_subscription_charge_result = stub.update_subscription_charge(Revenue::UpdateSubscriptionChargeReq.new(
        {
          amount: subscription_instance.total_amount.to_f,
          versionNumber: subscription_instance.version_number,
          description: plan(subscription_instance).description,
          subscriptionChargeId: subscription_instance.pinet_subscription_charge_id,
        }
      ))

      if update_subscription_charge_result.status == "approved"
        subscription_instance_item.approve!
        update_subscription_instance_total_amount(subscription_instance_item.fee_amount)
      elsif update_subscription_charge_result.status == "rejected"
        subscription_instance_item.reject!
      end
    rescue GRPC::BadStatus => e
      raise StandardError, "Error updating subscription charge: #{e.message}"
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
