# frozen_string_literal: true

require 'rails_helper'
require 'auth_token_services_pb'
require Rails.root.join('app/services/grpc/server/auth_token_service')

RSpec.describe AuthTokenService do
  let(:auth_service) { described_class.new }
  let(:token) { JWT.encode(payload, ENV['SECRET_KEY_BASE'], 'HS256') }
  let(:payload) { { 'exp' => Time.now.to_i + 60 * 60 } }
  let(:token_req) { Auth::AuthRequest.new(token: token) }

  describe '#verify' do
    context 'when the token is valid' do
      it 'returns a response with status succeed' do
        response = auth_service.verify(token_req, nil)
        expect(response.status).to eq('succeed')
      end
    end

    context 'when the token is invalid' do
      let(:token) { 'invalid_token' }

      it 'returns a response with status failed' do
        response = auth_service.verify(token_req, nil)
        expect(response.status).to eq('failed')
      end
    end

    context 'when the token is expired' do
      let(:payload) { { 'exp' => Time.now.to_i - 60 * 60 } }

      it 'raise and error with message Signature has expired' do
        begin
          response = auth_service.verify(token_req, nil)
        rescue JWT::ExpiredSignature
          response = "Signature has expired"
        end

        expect(response).to eq('Signature has expired')
      end
    end
  end
end
