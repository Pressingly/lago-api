# frozen_string_literal: true

require 'aws_avp'

module V1
  module Entitlement
    class AuthorizationController < ApplicationController
      def index
        request_params_valid = Authorization::AuthorizeValidator.new(authorization_params).valid?

        return render(json: failure_response(code: 422, message: "Request payload error")) unless request_params_valid

        payload = read_payload

        authorized_result = authorize(payload)

        if authorized_result[:is_authorized]
          # create GetLago event based on authorized_result[:subscription_plan]
          create_get_lago_event(authorized_result[:subscription_plan], request)

          return render(json: success_response(message: "Authorized", extra: authorized_result[:subscription_plan]))
        end

        render(
          json: failure_response(message: "Your subscriptions are expired")
        )
      end

      private

      def read_payload
        JSON.parse(request.body.read)
      end

      def authorization_params
        params.permit(
          :userId,
          :publisherId,
          :actionName,
          :timestamp,
          context: {},
          resource: [:id, :name, :type, :author, :tags, :category]
        )
      end

      def create_get_lago_event(subscription_plan, request)
        ConsumptionEvent::EmitService.call(subscription_plan: subscription_plan, request: request)
      end

      def authorize(payload)
        auth_payload = EntitlementAdapter::ConverterService.call(payload: payload, policy_store_id: policy_store_id)
        Authorization::AuthorizeService.call(payload: auth_payload, client: AwsAvp.init)
      end

      def policy_store_id
        ENV['AUTHENTICATION_POLICY_STORE_ID']
      end

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
