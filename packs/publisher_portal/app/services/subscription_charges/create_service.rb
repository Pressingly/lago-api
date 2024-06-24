# frozen_string_literal: true

require 'revenue.service_services_pb'

module SubscriptionCharges
  class CreateService < BaseService
    def initialize(subscription_instance:)
      @subscription_instance = subscription_instance

      super
    end

    def call
      customer = Customer.joins(:subscriptions)
        .find_by(subscriptions: { id: subscription_instance.subscription_id})
      plan = Plan.joins(:subscriptions)
        .find_by(subscriptions: {id: subscription_instance.subscription_id})

      stub.create_subscription_charge(Revenue::CreateSubscriptionChargeReq.new(
        {
          amount: subscription_instance.total_amount.to_f,
          currencyCode: customer.currency,
          versionNumber: subscription_instance.version_number,
          description: plan.description,
          pinetIdToken: customer.pinet_id_token,
          subscriptionInstanceId: subscription_instance.id,
        }
      ))
    rescue GRPC::BadStatus => e
      raise StandardError, "Error creating subscription charge: #{e.message}"
    end

    attr_reader :subscription_instance

    private

    def stub
      Revenue::RevenueGrpcService::Stub.new(
        ENV['PUBLISHER_REVENUE_GRPC_URL'],
        :this_channel_is_insecure
      )
    rescue GRPC::BadStatus => e
      raise StandardError, "Error connecting to Revenue Service: #{e.message}"
    end
  end
end
