# frozen_string_literal: true

require 'grpc'
require 'auth_token_services_pb'

module Grpc
  module Server
    class AuthTokenService < Auth::Token::Service
      def verify(token_req, _unused_call)
        if token_req.token && decoded_token(token_req.token) && valid_token?
          Auth::AuthResponse.new(status: "succeed")
        else
          Auth::AuthResponse.new(status: "failed")
        end
      end

      private

      def decoded_token(token)
        decoded_token ||= JWT.decode(token, ENV['SECRET_KEY_BASE'], true, decode_options)
        @payload = decoded_token.reduce({}, :merge)
      rescue JWT::DecodeError => e
        Rails.logger.error("Error decoding token: #{e}")
        raise e if e.is_a?(JWT::ExpiredSignature) || Rails.env.development?
      end

      def valid_token?
        Time.now.to_i <= @payload['exp']
      end

      def decode_options
        {
          algorithm: 'HS256',
        }
      end
    end
  end
end
