# frozen_string_literal: true

require 'aws-sdk-verifiedpermissions'

module V1
  module Entitlement
    class AuthorizationController < Api::BaseController
      before_action :set_customer
      def index
        # TODO: refactor AuthorizeValidator to include customer validation
        request_params_valid = Authorization::AuthorizeValidator.new(authorization_params).valid?
        return render(json: failure_response(code: 422, message: "Request payload error")) unless request_params_valid

        # Check if customer exists and has active subscriptions
        customer_error = check_customer_errors
        return render(json: customer_error) if customer_error

        # Check if policy store exists
        unless policy_store
          return render(json: failure_response(code: 404, message: 'No policy store found'), status: :not_found)
        end

        payload = read_payload

        authorized_result = authorize(payload)
        unless authorized_result[:is_authorized]
          return render(json: failure_response(message: "Your subscriptions are expired"))
        end

        handle_authorized_request(authorized_result)
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
          region: ENV.fetch('AWS_REGION', nil),
          credentials: Aws::Credentials.new(ENV.fetch('AWS_ACCESS_KEY_ID', nil), ENV.fetch('AWS_SECRET_ACCESS_KEY', nil))
        })
        auth_payload = EntitlementAdapter::ConverterService.call(payload: payload, policy_store_id: policy_store.id)
        Authorization::AuthorizeService.call(payload: auth_payload, client: avp_client)
      end

      def policy_store
        @policy_store ||= PolicyStore.find_by(organization_id: current_organization.id)
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

      def check_customer_errors
        if @customer.nil?
          return failure_response(code: 200, message: 'Not found customer')
        elsif @customer.active_subscriptions.empty?
          return failure_response(code: 200, message: 'No active subscription found')
        end

        nil
      end

      def handle_authorized_request(authorized_result)
        event_result = create_get_lago_event(authorized_result[:subscription_plan], request)
        Rails.logger.info("Event result: #{event_result.inspect}")
        if event_result&.success?
          render(json: success_response(message: "Authorized", extra: authorized_result[:subscription_plan]))
        else

          # TODO: add error code to failure response
          render(json: failure_response(message: 'Failed to create consumption event'))
        end
      end
    end
  end
end
