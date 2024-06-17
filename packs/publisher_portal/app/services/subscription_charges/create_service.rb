# frozen_string_literal: true

require_relative '../../../../../grpc/publisher_revenue/client/lib/subscription_charge.service_services_pb'

module SubscriptionCharges
  class CreateService < BaseService
    def initialize(subscription:)
      @subscription = subscription

      super
    end

    def call
      hostname = 'http://localhost:5002'
      stub = SubscriptionCharge::SubscriptionChargeGrpcService::Stub.new(hostname)

      stub.create_subscription_charge(SubscriptionCharge::CreateSubscriptionChargeReq.new(
        pinetIdToken: 'pinetIdToken',
        pinetUserId: 'pinetUserId',
        membershipOrgId: 'membershipOrgId',
        subscriptionInstanceId: sub_instance.id
      ))
    end

    attr_reader :subscription

    private
  end
end
