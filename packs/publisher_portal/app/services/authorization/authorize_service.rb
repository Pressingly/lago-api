# frozen_string_literal: true

require 'aws_avp'

module Authorization
  class AuthorizeService < BaseService
    attr_reader :payload
    def initialize(payload:)
      @client = AwsAvp.init
      @payload = payload

      super
    end

    def call
      client = AwsAvp.init
      client.is_authorized(@payload)
    end
  end
end
