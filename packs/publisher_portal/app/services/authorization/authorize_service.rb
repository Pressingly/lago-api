# frozen_string_literal: true

require 'aws_avp'

module Authorization
  class AuthorizeService < BaseService
    def initialize(payload:)
      @client = AwsAvp.init
      @payload = payload

      super
    end

    def call
      authorized_resp = @client.is_authorized(@payload)

      if authorized_resp[:decision] == 'ALLOW'
        plans = get_plans_by_policies(authorized_resp[:determining_policies].map(&:policy_id))
        best_plan = select_the_best_plan(plans)
      end

      {
        is_authorized: authorized_resp[:decision] == 'ALLOW',
        subscription_plan: best_plan
      }
    end

    private

    attr_reader :payload

    def get_plans_by_policies(policies)
      plans = Plan.where(id: AuthorizationPolicy.where(cedar_policy_id: policies).pluck(:plan_id))
      result = []
      policies.each_with_index do |policy_id, index|
        result << {
          policy_id: policy_id,
          plan: plans[index]
        }
      end

      result
    end

    def select_the_best_plan(plans)
      plans.first
    end
  end
end
