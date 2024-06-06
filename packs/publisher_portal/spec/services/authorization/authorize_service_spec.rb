# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Authorization::AuthorizeService, type: :service do
  subject(:authorize_service) { described_class.new(payload: payload, client: client) }

  let(:user) { create(:user) }
  let(:plan) { create(:plan) }
  let(:policy) { create(:authorization_policy, plan_id: plan.id) }
  let(:client) {
    Aws::VerifiedPermissions::Client.new(
      stub_responses:
      {is_authorized: {
        decision: "ALLOW",
        determining_policies: [
          {policy_id: policy.cedar_policy_id},
        ],
        errors: []
      }}
    )
  }
  let(:payload) {
    {policy_store_id: "C67cCCM1qXiox3Uh6f6JzQ",
     principal: {entity_type: "ABCNews::Subscriber",
                 entity_id: user.id},
     action: {action_type: "ABCNews::Action", action_id: "Read"},
     resource: {entity_type: "ABCNews::ResourceGroup", entity_id: "article"},
     context: {context_map: {}},
     entities: {entity_list: [{identifier: {
                                 entity_type: "ABCNews::Subscriber",
                                 entity_id: user.id
                               },
                               parents: [
                                 {entity_type: "ABCNews::SubscriptionPlan",
                                  entity_id: plan.id}
                               ]},
       {identifier: {entity_type: "ABCNews::Article", entity_id: "article"},
        parents: [{entity_type: "ABCNews::ResourceGroup", entity_id: "article"}]}]}}
  }
  let(:authorized_resp) { { decision: 'ALLOW', determining_policies: [OpenStruct.new(policy_id: 1)] } }
  let(:body) { { decision: 'ALLOW', determining_policies: [OpenStruct.new(policy_id: 1)] } }

  before {
    payload
  }

  describe '#call' do
    it 'returns a response with is_authorized and subscription_plan' do
      result = authorize_service.call

      plan_hash = plan.attributes
      plan_hash["policy_id"] = policy.cedar_policy_id
      expect(result[:is_authorized]).to eq(true)
      expect(result[:subscription_plan]).to eq(plan_hash)
    end

    context 'when the decision is not ALLOW' do
      let(:client) {
        Aws::VerifiedPermissions::Client.new(
          stub_responses:
          {is_authorized: {
            decision: "DENY",
            determining_policies: [],
            errors: []
          }}
        )
      }

      it 'returns a response with is_authorized as false' do
        result = authorize_service.call
        expect(result[:is_authorized]).to eq(false)
      end
    end

    context 'when there are no plans' do
      before do
        allow(Plan).to receive(:where).and_return([])
      end

      it 'returns a response with is_authorized as false' do
        result = authorize_service.call
        expect(result[:is_authorized]).to eq(false)
      end
    end
  end
end
