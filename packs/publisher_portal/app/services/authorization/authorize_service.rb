# frozen_string_literal: true

module Authorization
  class AuthorizeService < BaseService
    def initialize(payload:, client:)
      @client = client
      @payload = payload

      super
    end

    def call
      authorized_resp = client.is_authorized(payload)
      policies = authorized_resp.determining_policies.map { |p| p.policy_id }
      plans = get_plans_by_policies(policies)
      Rails.logger.info("Customer subscription plans: #{plans.inspect}")

      resp = {
        is_authorized: authorized_resp.decision == 'ALLOW',
        subscription_plan: nil
      }

      if plans.empty?
        resp[:is_authorized] = false
      end

      if authorized_resp.decision == 'ALLOW'
        best_plan = select_the_best_plan(plans)
        resp[:subscription_plan] = best_plan
      end

      Rails.logger.info("AVP result: #{authorized_resp.inspect}")

      resp
    end

    private

    attr_reader :payload, :client

    def get_plans_by_policies(policies)
      policy_plan_mapping = AuthorizationPolicy.where(cedar_policy_id: policies).pluck(:cedar_policy_id, :plan_id).to_h
      plans = Plan.where(id: policy_plan_mapping.values).index_by(&:id)

      return [] if plans.empty?

      result = []
      policies.each_with_index do |policy_id, index|
        plan_id = policy_plan_mapping[policy_id]
        next unless plan_id && plans[plan_id]

        plan = plans[plan_id].attributes
        plan["policy_id"] = policy_id
        result << plan
      end

      result
    end

    def select_the_best_plan(plans)
      plans.first
    end
  end
end
