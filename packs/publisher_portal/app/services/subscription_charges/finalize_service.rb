# frozen_string_literal: true

module SubscriptionCharges
  class FinalizeService < BaseService
    include ServiceHelper

    def initialize(subscription_instance:, subscription_instance_items: [])
      @subscription_instance = subscription_instance
      @subscription_instance_items = subscription_instance_items

      super
    end

    def call
      customer = subscription_instance.subscription.customer
      plan = subscription_instance.subscription.plan
      payload = {
        subscriptionChargeId: subscription_instance.pinet_subscription_charge_id,
        versionNumber: subscription_instance.version_number,
        amount: total_amount.to_f,
        currencyCode: customer.currency,
        description: plan.description,
        pinetIdToken: customer.pinet_id_token,
      }

      finalize_result = stub.finalize_subscription_charge(Revenue::FinalizeSubscriptionChargeReq.new(payload))

      # TODO: depending on finalize api, we may need to handle different ways
      # for now, i assume that the finalize api allow updating total mount of subscription charge
      if finalize_result.success
        ActiveRecord::Base.transaction do
          subscription_instance_items.each do |item|
            item.approve!
          end
        end

        finalize_subscription_instance
      end
      Rails.logger.info("Subcription charge finalization payload: #{payload}")
      stub.finalize_subscription_charge(Revenue::FinalizeSubscriptionChargeReq.new(payload))

      result
    rescue GRPC::BadStatus => e
      result.service_failure!(code: 'grpc_failed', message: "finalize subscription charge: #{e.message}")
    end

    private

    attr_reader :subscription_instance, :subscription_instance_items

    def total_amount
      subscription_instance_items.sum(&:fee_amount)
    end

    def finalize_subscription_instance
      SubscriptionInstances::IncreaseTotalValueService.call(
        subscription_instance: subscription_instance,
        fee_amount: total_amount
      )
      subscription_instance.finalize!
    end
  end
end
