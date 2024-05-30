# frozen_string_literal: true

module V1
  module Entitlement
    class AuthorizationController < ApplicationController
      def index
        request_params_valid = AuthorizeValidator.new(request.params).valid?

        return render(json: failure_response(code: 422, message: "Request payload error")) if !request_params_valid

        payload = JSON.parse(request.body.read)
        policy_store_id = ENV['AUTHENTICATION_POLICY_STORE_ID']

        auth_payload = EntitlementAdapter::ConverterService.call(payload: payload, policy_store_id: policy_store_id)
        authorized_result = Authorization::AuthorizeService.call(payload: auth_payload)

        if authorized_result[:is_authorized]
          # create GetLago event based on authorized_result[:subscription_plan]

          return render(json: success_response(message: "Authorized", extra: authorized_result[:subscription_plan]))
        end

        render(
          json: failure_response(message: "Your subscriptions are expired")
        )
      end

      private

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
