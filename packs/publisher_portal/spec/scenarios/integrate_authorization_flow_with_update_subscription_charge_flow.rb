# frozen_string_literal: true

require 'rails_helper'

describe 'Integrate authorization flow with update subscription charge flow', :senarios, type: :request do
  let(:organization) { create(:organization, webhook_url: false, default_currency: 'USD') }
  let(:customer) { create(:customer, organization:, currency: 'USD') }
  let(:billable_metric) { create(:billable_metric, organization:) }
  let(:base_amount) { 2 }
  let(:charge_amount) { 0.1 }
  let(:plan) do
    create(
      :plan,
      organization:,
      interval: :weekly,
      pay_in_advance: true,
      amount_cents: base_amount * 100,
      amount_currency: 'USD'
    )
  end

  let(:policy) { create(:authorization_policy, plan_id: plan.id) }
  let(:subscription_plan) { plan.attributes }
  let(:charge) {
    create(:standard_charge,
      billable_metric: billable_metric,
      plan:,
      properties: { amount: charge_amount.to_s },
      pay_in_advance: true)
  }

  let(:policy_store) { create(:policy_store) }
  let(:policy_store_id) { policy_store.id }

  let(:is_authorized_resp) {
    OpenStruct.new(
      decision: "ALLOW",
      determining_policies: [
        OpenStruct.new(policy_id: policy.cedar_policy_id),
      ],
      errors: []
    )
  }

  let(:avp_client) do
    instance_double(Aws::VerifiedPermissions::Client, is_authorized: is_authorized_resp)
  end

  let(:base_params) do
    {
      externalCustomerId: customer.external_id,
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
    subscription_plan["policy_id"] = policy.cedar_policy_id
    allow(Aws::VerifiedPermissions::Client).to receive(:new).and_return(avp_client)

    charge
  end

  context 'when not have any active subscription' do
    it 'return Deny' do
      post_with_token(organization, '/v1/entitlement/authorize', base_params)
      response_body = JSON.parse(response.body)

      expect(response_body['status']).to eq('Deny')
    end
  end

  context 'when has an active subscription' do
    before do
      charge

      allow(Invoices::CreatePayInAdvanceChargeJob).to receive(:perform_now).and_call_original
    end

    it 'creates a subscription instance and a base charge item correctly' do
      create_subscription(
        external_customer_id: customer.external_id,
        external_id: "#{customer.external_id}_1",
        plan_code: plan.code,
        billing_time: :anniversary
      )

      post_with_token(organization, '/v1/entitlement/authorize', base_params)
      expect(Invoices::CreatePayInAdvanceChargeJob).to have_received(:perform_now)

      subscription = Subscription.find_by(external_id: "#{customer.external_id}_1")
      expect(subscription).to be_present

      expect(subscription.subscription_instances.count).to eq(1)
      subscription_instance = subscription.subscription_instances.first

      expect(subscription_instance.subscription_instance_items.usage_charge.count).to eq(1)
      usage_charge_item = subscription_instance.subscription_instance_items.usage_charge.last
      expect(usage_charge_item.fee_amount).to eq(charge_amount)

      response_body = JSON.parse(response.body)
      expect(response_body['status']).to eq('Allow')
    end
  end
end
