# frozen_string_literal: true

require_relative '../../../../../grpc/publisher_revenue/client/lib/subscription_charge.service_services_pb'

module SubscriptionCharges
  class CreateService < BaseService
    def initialize(authorized_result:, request_payload:)
      @authorized_result = authorized_result
      @request_payload = request_payload

      super
    end

    def call
      plan_id = authorized_result[:subscription_plan]["id"]

      user_id = request_payload["userId"]

      subscription = Subscription
        .joins(:plan, :customer)
        .where(
          customer_id: user_id,
          plan_id: plan_id,
          terminated_at: nil,
          canceled_at: nil
        ).first
      puts "subscription: #{subscription.inspect}"
      sub_instance = SubscriptionInstances::CreateService.new(subscription: subscription).call

      puts "subscription_instance:  #{sub_instance}"

      hostname = 'http://localhost:5002'
      stub = SubscriptionCharge::SubscriptionChargeGrpcService::Stub.new(hostname)

      stub.create_subscription_charge(SubscriptionCharge::CreateSubscriptionChargeReq.new(
        pinetIdToken: 'pinetIdToken',
        pinetUserId: 'pinetUserId',
        membershipOrgId: 'membershipOrgId',
        subscriptionInstanceId: sub_instance.id
      ))
    end

    attr_reader :authorized_result, :request_payload

    private
  end
end
