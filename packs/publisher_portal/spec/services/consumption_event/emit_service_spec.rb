# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ConsumptionEvent::EmitService, type: :service do
  subject(:emit_service) { described_class.new(subscription_plan: subscription_plan, request: request) }

  let(:organization) { create(:organization) }
  let(:plan) { create(:plan, organization: organization) }
  let(:policy) { create(:authorization_policy, plan_id: plan.id) }
  let(:subscription_plan) { plan.attributes }
  let(:customer) { create(:customer) }
  let(:request) { instance_double('ActionDispatch::Request', body: StringIO.new("{\"externalCustomerId\": \"#{customer.external_id}\"}"), user_agent: 'TestAgent', remote_ip: '127.0.0.1') }
  let(:subscription) { create(:subscription, plan: plan, customer_id: customer.id) }
  let(:billable_metric) { create(:billable_metric, organization: organization) }
  let(:charge) { create(:standard_charge, plan: plan, billable_metric: billable_metric) }

  describe '#call' do
    before do
      subscription_plan["policy_id"] = policy.cedar_policy_id
      subscription
      customer
      request
      billable_metric
      charge
      plan
    end

    it 'creates an event' do
      success_reult = BaseService::Result.new
      success_reult.event = Event.new
      allow(::Events::Sync::CreateSyncService).to receive(:call)
        .and_return(success_reult)
      result = emit_service.call

      expect(result.success?).to eq(true)
      expect(result.event).to be_present
    end

    context 'when the subscription plan is invalid' do
      let(:subscription_plan) { { "id" => "1", "organization_id" => nil } }

      it 'raises an ArgumentError' do
        result = emit_service.call
        expect(result.success?).to eq(false)
        expect(result.error).to be_a(ArgumentError)
      end
    end

    context 'when the event creation fails' do
      let(:failed_result) { BaseService::Result.new.fail_with_error!(StandardError.new("Error message")) }

      before do
        allow(::Events::Sync::CreateSyncService).to receive(:call).and_return(failed_result)
      end

      it 'triggers render_error_response' do
        result = emit_service.call

        expect(result.success?).to eq(false)
        expect(result.error).to be_a(StandardError)
      end
    end
  end
end
