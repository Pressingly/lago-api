# frozen_string_literal: true

module V1
  module Entitlement
    class AuthorizationController < ApplicationController
      def index
        payload = JSON.parse(request.body.read)
        avp_store_id = ENV['AVP_POLICY_STORE_ID']

        auth_payload = EntitlementAdapter::ConverterService.call(payload: payload, avp_store_id: avp_store_id)
        # puts "auth_payload: #{auth_payload}"
        is_authorized = Authorization::AuthorizeService.call(payload: auth_payload)

        puts "is_authorized: #{is_authorized}"

        render(
          json: {
            message: 'Success',
          },
          status: :ok,
        )
      end
    end
  end
end
