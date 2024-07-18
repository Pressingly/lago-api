# frozen_string_literal: true

module ConsumptionEvent
  class EmitService < BaseService
    include ApiErrors

    def initialize(subscription_plan:, request:)
      @subscription_plan = subscription_plan
      @request = request

      super
    end

    def call
      validate_subscription_plan(subscription_plan)

      event_params = create_params(subscription_plan["id"], JSON.parse(request.body.read))
      return result if event_params[:code].blank?

      ::Events::Sync::CreateSyncService.call(
        organization: current_organization(subscription_plan["organization_id"]),
        params: event_params,
        timestamp: Time.current.to_f,
        metadata: event_metadata(request),
      )
    rescue => e
      result.fail_with_error!(e)
    end

    attr_reader :subscription_plan, :request

    private

    def validate_subscription_plan(subscription_plan)
      ["id", "organization_id"].each do |key|
        unless subscription_plan.has_key?(key) && subscription_plan[key].is_a?(String)
          raise ArgumentError, "'#{key}' must be present and must be a string"
        end
      end
    end

    def current_organization(organization_id)
      Organization.find_by(id: organization_id)
    end

    def event_metadata(request)
      {
        user_agent: request.user_agent,
        ip_address: request.remote_ip,
      }
    end

    def create_params(plan_id, req_payload)
      customer = Customer.find_by(external_id: req_payload["externalCustomerId"])
      subscription = Subscription.find_by(plan_id: plan_id, customer_id: customer.id, status: :active)

      # TODO: a plan can have multiple billable metrics. Do we emit one consumption event per billable metric?
      # https://thepressingly.atlassian.net/browse/PINET-383
      billable_metric = subscription.plan.billable_metrics.first
      external_subscription_id = subscription.external_id

      {
        transaction_id: SecureRandom.uuid,
        code: billable_metric&.code,
        external_subscription_id: external_subscription_id,
        timestamp: Time.current.to_f
      }
    end
  end
end
