# frozen_string_literal: true

require 'rails_helper'

describe 'Create and update subscription instance Scenario', :scenarios, type: :request do
  let(:organization) { create(:organization, webhook_url: false, default_currency: 'USD') }
  let(:customer) { create(:customer, organization:, currency: 'USD') }
  let(:billable_metric) { create(:billable_metric, organization:) }

  let(:plan) do
    create(
      :plan,
      organization:,
      interval: :weekly,
      pay_in_advance: true,
      amount_cents: 2000,
      amount_currency: 'USD'
    )
  end
  let(:charge) {
    create(:standard_charge,
      billable_metric: billable_metric,
      plan:,
      pay_in_advance: true)
  }

  context 'when creating a subscription' do
    it 'creates a subscription instance and a base charge item correctly' do
      create_subscription(
        external_customer_id: customer.external_id,
        external_id: "#{customer.external_id}_1",
        plan_code: plan.code,
        billing_time: :anniversary
      )

      subscription = Subscription.find_by(external_id: "#{customer.external_id}_1")
      expect(subscription).to be_present
      expect(subscription.subscription_instances.count).to eq(1)
      expect(subscription.subscription_instances.first.subscription_instance_items.count).to eq(1)

      subscription_instance = subscription.subscription_instances.first
      subscription_instance_item = subscription_instance.subscription_instance_items.first
      expect(subscription_instance.status.to_sym).to eq(:active)
      expect(subscription_instance.total_amount).to eq(plan.amount_cents.fdiv(plan.amount.currency.subunit_to_unit))
      expect(subscription_instance_item.charge_type.to_sym).to eq(:base_charge)
    end
  end

  context 'when adding a usage event' do
    let(:event_params) do
      {
        code: billable_metric.code,
        transaction_id: SecureRandom.uuid,
        external_customer_id: customer.external_id,
      }
    end

    before { charge }

    it 'creates a usage charge item and increases total amount' do
      create_subscription(
        external_customer_id: customer.external_id,
        external_id: "#{customer.external_id}_1",
        plan_code: plan.code,
        billing_time: :anniversary
      )

      create_event event_params
      perform_all_enqueued_jobs

      subscription = Subscription.find_by(external_id: "#{customer.external_id}_1")
      expect(subscription).to be_present

      subscription_instance = subscription.subscription_instances.first
      debugger
      subscription_instance_item = subscription_instance.subscription_instance_items.where(charge_type: :usage_charge).first
      expect(subscription_instance_item).to be_present

      expect(subscription_instance_item.fee_amount).to eq(BigDecimal(charge.properties['amount']))
    end
  end
end
