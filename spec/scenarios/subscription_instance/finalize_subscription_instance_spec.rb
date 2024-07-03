# frozen_string_literal: true

require 'rails_helper'

describe 'Finalize Subscription Instance Scenario', :scenarios, type: :request do
  let(:organization) { create(:organization, webhook_url: false, default_currency: 'USD') }
  let(:customer) { create(:customer, organization:, currency: 'USD') }
  let(:billable_metric) { create(:billable_metric, organization:, aggregation_type: 'count_agg') }
  let(:subscription_at) { DateTime.new(2024, 6, 20, 10, 30) }
  let(:plan_in_advance) do
    create(
      :plan,
      organization:,
      interval: :weekly,
      pay_in_advance: true,
      amount_cents: 2000,
      amount_currency: 'USD'
    )
  end

  let(:plan_in_arreas) do
    create(
      :plan,
      organization:,
      interval: :weekly,
      pay_in_advance: false,
      amount_cents: 2000,
      amount_currency: 'USD'
    )
  end

  let(:currency) { plan_in_advance.amount.currency }

  let(:stub) { instance_double(Revenue::RevenueGrpcService::Stub) }

  before do
    allow(SubscriptionCharges::CreateService).to receive(:call).and_call_original
    allow(SubscriptionCharges::FinalizeService).to receive(:call).and_call_original
    allow(Revenue::RevenueGrpcService::Stub).to receive(:new).and_return(stub)

    # TODO: update return value to match the actual return value
    allow(stub).to receive(:create_subscription_charge).and_return(OpenStruct.new(status: 'approved'))
    allow(stub).to receive(:finalize_subscription_charge).and_return(OpenStruct.new(success: true))
  end

  context 'when plan has only base amount' do
    context 'when plan is pay in advance' do
      it 'finalizes subscription instance correctly' do
        travel_to(subscription_at) do
          create_subscription(
            external_customer_id: customer.external_id,
            external_id: "#{customer.external_id}_1",
            plan_code: plan_in_advance.code,
            billing_time: :anniversary,
            subscription_at: subscription_at.iso8601
          )

          subscription = Subscription.find_by(external_id: "#{customer.external_id}_1")
          subscription_instance = subscription.subscription_instances.first

          expect(subscription.subscription_instances.count).to eq(1)

          expect(subscription_instance.status.to_sym).to eq(:active)
          expect(subscription_instance.total_amount).to eq(plan_in_advance.amount_cents.fdiv(currency.subunit_to_unit))
        end

        travel_to(subscription_at + 1.week) do
          Subscriptions::BillingService.call
          perform_all_enqueued_jobs

          subscription = Subscription.find_by(external_id: "#{customer.external_id}_1")
          finalized_subscription_instance = subscription.subscription_instances.where(status: :finalized).first
          active_subscription_instance = subscription.subscription_instances.where(status: :active).first
          expected_started_at = (subscription_at + 1.week).beginning_of_day
          expected_end_at = (expected_started_at + 6.days).end_of_day

          expect(subscription.subscription_instances.count).to eq(2) # 1 for the initial subscription instance and 1 for the new one

          expect(finalized_subscription_instance).to be_present
          expect(finalized_subscription_instance.total_amount).to eq(plan_in_advance.amount_cents.fdiv(currency.subunit_to_unit))

          expect(active_subscription_instance).to be_present
          expect(active_subscription_instance.total_amount).to eq(plan_in_advance.amount_cents.fdiv(currency.subunit_to_unit))

          expect(active_subscription_instance.started_at.to_i).to eq(expected_started_at.to_i)
          expect(active_subscription_instance.ended_at.to_i).to eq(expected_end_at.to_i)
        end
      end
    end

    context 'when plan is pay in arrears' do
      it 'finalizes subscription instance correctly' do
        travel_to(subscription_at) do
          create_subscription(
            external_customer_id: customer.external_id,
            external_id: "#{customer.external_id}_1",
            plan_code: plan_in_arreas.code,
            billing_time: :anniversary,
            subscription_at: subscription_at.iso8601
          )

          subscription = Subscription.find_by(external_id: "#{customer.external_id}_1")
          subscription_instance = subscription.subscription_instances.first

          expect(subscription.subscription_instances.count).to eq(1)

          expect(subscription_instance.status.to_sym).to eq(:active)
          expect(subscription_instance.total_amount).to eq(0)
        end

        travel_to(subscription_at + 1.week) do
          Subscriptions::BillingService.call
          perform_all_enqueued_jobs

          subscription = Subscription.find_by(external_id: "#{customer.external_id}_1")
          finalized_subscription_instance = subscription.subscription_instances.where(status: :finalized).first
          active_subscription_instance = subscription.subscription_instances.where(status: :active).first
          expected_started_at = (subscription_at + 1.week).beginning_of_day
          expected_end_at = (expected_started_at + 6.days).end_of_day

          expect(subscription.subscription_instances.count).to eq(2) # 1 for the initial subscription instance and 1 for the new one

          # The total amount will be added to subscription instance at when the subscription instance is finalized
          expect(finalized_subscription_instance.total_amount).to eq(plan_in_arreas.amount_cents.fdiv(currency.subunit_to_unit))
          expect(finalized_subscription_instance.subscription_instance_items.pluck(:contract_status)).to eq(['approved'])

          # The total amount of next subscription instance will be 0 because its plan is pay in arrears
          expect(active_subscription_instance.total_amount).to eq(0)

          expect(active_subscription_instance.started_at.to_i).to eq(expected_started_at.to_i)
          expect(active_subscription_instance.ended_at.to_i).to eq(expected_end_at.to_i)
        end
      end
    end
  end

  context 'when plan is "pay in advance" and billable metric is "pay in arreas"' do
    let(:charge) {
      create(:standard_charge,
        billable_metric: billable_metric,
        plan: plan_in_advance,
        pay_in_advance: false,
        properties: { amount: '0.5' })
    }

    let(:number_of_events) { 10 }

    before do
      charge
    end

    it 'finalizes subscription instance correctly' do
      travel_to(subscription_at) do
        create_subscription(
          external_customer_id: customer.external_id,
          external_id: "#{customer.external_id}_1",
          plan_code: plan_in_advance.code,
          billing_time: :anniversary,
          subscription_at: subscription_at.iso8601
        )

        subscription = Subscription.find_by(external_id: "#{customer.external_id}_1")
        subscription_instance = subscription.subscription_instances.first

        expect(subscription.subscription_instances.count).to eq(1)

        expect(subscription_instance.status.to_sym).to eq(:active)
        expect(subscription_instance.total_amount).to eq(plan_in_advance.amount_cents.fdiv(currency.subunit_to_unit))
      end

      subscription = Subscription.find_by(external_id: "#{customer.external_id}_1")

      (1..number_of_events).each do |hour|
        travel_to(subscription_at + hour.hours) do
          create_event(
            code: billable_metric.code,
            transaction_id: SecureRandom.uuid,
            external_subscription_id: subscription.external_id
          )
        end
      end

      travel_to(subscription_at + 1.week) do
        Subscriptions::BillingService.call
        perform_all_enqueued_jobs

        subscription.reload
        finalized_subscription_instance = subscription.subscription_instances.where(status: :finalized).first
        expected_amount = plan_in_advance.amount_cents.fdiv(currency.subunit_to_unit) + BigDecimal(charge.properties['amount']) * number_of_events
        expect(finalized_subscription_instance).to be_present

        # The total amount will include the base charge and the usage charge during the billing period
        expect(finalized_subscription_instance.total_amount).to eq(expected_amount)
      end
    end
  end
end
