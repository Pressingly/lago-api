# frozen_string_literal: true

require 'revenue.service_services_pb'

module SubscriptionCharges
  module ServiceHelper
    def stub
      Revenue::RevenueGrpcService::Stub.new(
        ENV['PUBLISHER_REVENUE_GRPC_URL'],
        :this_channel_is_insecure
      )
    rescue GRPC::BadStatus => e
      raise StandardError, "Error connecting to Revenue Service: #{e.message}"
    end

    def plan(subscription_instance)
      Plan.joins(:subscriptions)
        .find_by(subscriptions: {id: subscription_instance.subscription_id})
    end
  end
end
