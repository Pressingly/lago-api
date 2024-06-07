# frozen_string_literal: true

require 'rails_helper'

RSpec.describe V1::Entitlement::AuthorizationController, type: :request do
  describe 'authorize' do
    let(:organization) { create(:organization) }
    let(:plan) { create(:plan, organization: organization) }
    let(:policy) { create(:authorization_policy, plan_id: plan.id) }
    let(:subscription_plan) { plan.attributes }
    let(:customer) { create(:customer) }
    let(:subscription) { create(:subscription, plan: plan, customer_id: customer.id) }
    let(:billable_metric) { create(:billable_metric, organization: organization) }
    let(:charge) { create(:standard_charge, plan: plan, billable_metric: billable_metric) }
    let(:policy_store) { create(:policy_store) }
    let(:policy_store_id) { policy_store.id }
    let(:headers) do
      {
        "Authorization" => "Bearer #{organization.api_key}",
        "Content-Type" => "application/json",
        "Accept" => "application/json"
      }
    end

    let(:is_authorized_resp) {
      {
        decision: "ALLOW",
        determining_policies: [
          {policy_id: policy.cedar_policy_id},
        ],
        errors: []
      }
    }
    let(:avp_client) do
      instance_double(Aws::VerifiedPermissions::Client, is_authorized: is_authorized_resp)
    end

    let(:base_params) do
      {
        userId: customer.id,
        publisherId: "Publisher id we create for the publisher when they are onboarded",
        actionName: "read",
        context: {},
        resource: {
          id: "2fc41fd4-70fd-4b23-95bc-bb3a98af2f9d",
          name: "Liverpool is winning Champion League",
          type: "article",
          author: "author name",
          tags: ["Climate change"],
          category: "basketball"
        },
        timestamp: "2022-03-01T12:34:56+02:00"
      }
    end

    before do
      ENV['AUTHENTICATION_POLICY_STORE_ID'] = policy_store_id
      subscription
      customer
      request
      billable_metric
      charge
      plan
      subscription_plan["policy_id"] = policy.cedar_policy_id
      allow(Aws::VerifiedPermissions::Client).to receive(:new).and_return(avp_client)
    end

    context 'when the request is successful' do
      it 'returns a 200 status code' do
        post('/v1/entitlement/authorize', params: base_params.to_json, headers: headers)

        expect(JSON.parse(response.body)["code"]).to eq(200)
      end
    end

    context 'when no Cedar return unauthorized' do
      let(:is_authorized_resp) {
        {
          decision: "DENY",
          determining_policies: [],
          errors: []
        }
      }
      let(:avp_client) do
        instance_double(Aws::VerifiedPermissions::Client, is_authorized: is_authorized_resp)
      end

      it 'returns a 401 status code' do
        post('/v1/entitlement/authorize', params: base_params.to_json, headers: headers)

        expect(JSON.parse(response.body)["code"]).to eq(401)
      end
    end

    context 'when no userId is provided' do
      let(:params) { base_params.except(:userId) }

      it 'returns a 422 status code' do
        post('/v1/entitlement/authorize', params: params.to_json, headers: headers)

        expect(JSON.parse(response.body)["code"]).to eq(422)
      end
    end
  end
end
