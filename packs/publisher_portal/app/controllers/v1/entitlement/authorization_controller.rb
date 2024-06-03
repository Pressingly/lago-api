# frozen_string_literal: true

require 'aws_avp'

module V1
  module Entitlement
    class AuthorizationController < ApplicationController
      def index
        request_params_valid = Authorization::AuthorizeValidator.new(params).valid?

        return render(json: failure_response(code: 422, message: "Request payload error")) if !request_params_valid

        payload = JSON.parse(request.body.read)
        policy_store_id = ENV['AUTHENTICATION_POLICY_STORE_ID']

        auth_payload = EntitlementAdapter::ConverterService.call(payload: payload, policy_store_id: policy_store_id)
        authorized_result = Authorization::AuthorizeService.call(payload: auth_payload, client: AwsAvp.init)

        if authorized_result[:is_authorized]
          # create GetLago event based on authorized_result[:subscription_plan]
          # create_get_lago_event(authorized_result[:subscription_plan], request)

          return render(json: success_response(message: "Authorized", extra: authorized_result[:subscription_plan]))
        end

        render(
          json: failure_response(message: "Your subscriptions are expired")
        )
      end

      private

      # def create_get_lago_event(subscription_plan, request)
      #   puts "subscription_plan: #{subscription_plan}"
      #   result = ::Events::CreateService.call(
      #     organization: current_organization(subscription_plan[:organization_id]),
      #     params: create_params(subscription_plan[:id], JSON.parse(request.body.read)),
      #     timestamp: Time.current.to_f,
      #     metadata: event_metadata(request),
      #   )

      #   if result.success?
      #     render(
      #       json: ::V1::EventSerializer.new(
      #         result.event,
      #         root_name: 'event',
      #       ),
      #     )
      #   else
      #     render_error_response(result)
      #   end
      # end

      # def current_organization(organization_id)
      #   puts "organization_id: #{organization_id}"
      #   Organization.find_by(id: organization_id)
      # end

      # def event_metadata(request)
      #   {
      #     user_agent: request.user_agent,
      #     ip_address: request.remote_ip,
      #   }
      # end

      # def create_params(plan_id, req_payload)
      #   puts "plan_id: #{plan_id}"
      #   puts "req_payload: #{req_payload}"
      #   subscription = Subscription.find_by(plan_id: plan_id, customer_id: req_payload["userId"])
      #   puts "subscription: #{subscription.to_json}"
      # end

      def failure_response(code: 401, message: "Unauthorized", extra: {})
        {
          status: "Deny",
          code: code,
          message: message,
          extra: extra
        }.to_json
      end

      def success_response(code: 200, message: "OK", extra: {})
        {
          status: "Alow",
          code: code,
          message: message,
          extra: extra
        }
      end
    end
  end
end
