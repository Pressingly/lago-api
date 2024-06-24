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
      plans = Plan.where(id: AuthorizationPolicy.where(cedar_policy_id: policies).pluck(:plan_id))

      return [] if plans.empty?

      result = []
      policies.each_with_index do |policy_id, index|
        plan = plans[index].attributes
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
