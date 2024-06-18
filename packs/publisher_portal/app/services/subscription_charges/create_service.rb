# frozen_string_literal: true

require 'revenue.service_services_pb'

module SubscriptionCharges
  class CreateService < BaseService
    def initialize(subscription:)
      @subscription = subscription

      super
    end

    def call
      sub_instance = SubscriptionInstance.find_by(subscription_id: subscription.id)
      customer = Customer.find_by(id: subscription.customer_id)

      # TODO: dynamically set description and fraction
      stub.create_subscription_charge(Revenue::CreateSubscriptionChargeReq.new(
        {
          amount: sub_instance.total_amount.to_i,
          currencyCode: customer.currency,
          description: "eu reprehenderit aliquip",
          pinetIdToken: customer.pinet_id_token,
          subscriptionInstanceId: sub_instance.id,
        }
      ))
    rescue GRPC::BadStatus => e
      raise StandardError, "Error creating subscription charge: #{e.message}"
    end

    attr_reader :subscription

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
