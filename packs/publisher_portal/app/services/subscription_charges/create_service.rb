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
      charge = Charge.where(plan_id: subscription.plan_id).first

      # TODO: dynamically set description and fraction
      stub.create_subscription_charge(Revenue::CreateSubscriptionChargeReq.new(
        {
          amount: sub_instance.total_amount,
          currencyCode: charge.amount_currency,
          description: "eu reprehenderit aliquip",
          fraction: 2,
          pinetIdToken: customer.pinet_id_token,
          subscriptionInstanceId: sub_instance.id,
        }
      ))
    end

    attr_reader :subscription

    private

    def stub
      Revenue::RevenueGrpcService::Stub.new(ENV['PUBLISHER_REVENUE_GRPC_URL'], :this_channel_is_insecure)
    rescue GRPC::BadStatus => e
      abort "ERROR: #{e.message}"
    end
  end
end
