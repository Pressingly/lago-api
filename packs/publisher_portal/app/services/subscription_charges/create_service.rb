# frozen_string_literal: true

module SubscriptionCharges
  class CreateService < BaseService
    include ServiceHelper

    def initialize(subscription_instance:)
      @subscription_instance = subscription_instance
    end

    attr_reader :subscription_instance

    def call
      customer = Customer.joins(:subscriptions)
        .find_by(subscriptions: { id: subscription_instance.subscription_id})
      plan = Plan.joins(:subscriptions)
        .find_by(subscriptions: {id: subscription_instance.subscription_id})
      payload = {
        amount: subscription_instance.total_amount.to_f,
        currencyCode: customer.currency,
        versionNumber: subscription_instance.version_number,
        description: plan.description,
        pinetIdToken: customer.pinet_id_token,
        subscriptionInstanceId: subscription_instance.id,
      }

      stub.create_subscription_charge(Revenue::CreateSubscriptionChargeReq.new(payload))
      Rails.logger.info("Subcription charge creation payload: #{payload}")
    rescue GRPC::BadStatus => e
      raise StandardError, "Error creating subscription charge: #{e.message}"
    end
  end
end
