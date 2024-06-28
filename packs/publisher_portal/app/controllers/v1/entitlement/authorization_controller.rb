# frozen_string_literal: true

require 'aws-sdk-verifiedpermissions'

module V1
  module Entitlement
    class AuthorizationController < ApplicationController
      before_action :set_customer
      def index
        request_params_valid = Authorization::AuthorizeValidator.new(authorization_params).valid?
        return render(json: failure_response(code: 422, message: "Request payload error")) unless request_params_valid
        return render(json: failure_response(code: 200, message: 'Not found customer')) if @customer.nil?
        return render(json: failure_response(code: 200, message: 'No active subscription found')) if @customer.active_subscriptions.empty?

        payload = read_payload

        authorized_result = authorize(payload)
        if authorized_result[:is_authorized]
          event_result = create_get_lago_event(authorized_result[:subscription_plan], request)

          if event_result.success?
            return render(json: success_response(message: "Authorized", extra: authorized_result[:subscription_plan]))
          else
            # TODO: Handle error code
            error_code = case event_result.error
            when BaseService::ServiceFailure
              event_result.error.code
            end
            return render(json: failure_response(message: event_result.error.message, code: error_code))
          end
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
          :externalCustomerId,
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
        avp_client = Aws::VerifiedPermissions::Client.new({
          region: 'ap-southeast-1',
          credentials: Aws::Credentials.new(ENV.fetch('AWS_ACCESS_KEY_ID', nil), ENV.fetch('AWS_SECRET_ACCESS_KEY', nil))
        })
        auth_payload = EntitlementAdapter::ConverterService.call(payload: payload, policy_store_id: policy_store_id)
        Authorization::AuthorizeService.call(payload: auth_payload, client: avp_client)
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
          status: "Allow",
          code: code,
          message: message,
          extra: extra
        }
      end

      def set_customer
        @customer = Customer.find_by(external_id: params[:externalCustomerId])
      end
    end
  end
end
