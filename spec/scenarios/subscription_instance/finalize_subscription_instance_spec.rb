# frozen_string_literal: true

require 'rails_helper'

describe 'Finalize Subscription Instance Scenario', :scenarios, type: :request do
  let(:organization) { create(:organization, webhook_url: false, default_currency: 'USD') }
  let(:customer) { create(:customer, organization:, currency: 'USD') }
  let(:billable_metric) { create(:billable_metric, organization:) }
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
          expect(subscription.subscription_instances.count).to eq(1)

          subscription_instance = subscription.subscription_instances.first
          expect(subscription_instance.status.to_sym).to eq(:active)
          expect(subscription_instance.total_amount).to eq(plan_in_advance.amount_cents.fdiv(currency.subunit_to_unit))
        end

        travel_to(subscription_at + 1.week) do
          Subscriptions::BillingService.call
          perform_all_enqueued_jobs

          subscription = Subscription.find_by(external_id: "#{customer.external_id}_1")
          expect(subscription.subscription_instances.count).to eq(2) # 1 for the initial subscription instance and 1 for the new one

          finalized_subscription_instance = subscription.subscription_instances.where(status: :finalized).first
          expect(finalized_subscription_instance).to be_present
          expect(finalized_subscription_instance.total_amount).to eq(plan_in_advance.amount_cents.fdiv(currency.subunit_to_unit))

          active_subscription_instance = subscription.subscription_instances.where(status: :active).first
          expect(active_subscription_instance).to be_present
          expect(active_subscription_instance.total_amount).to eq(plan_in_advance.amount_cents.fdiv(currency.subunit_to_unit))

          expected_started_at = (subscription_at + 1.week).beginning_of_day
          expected_end_at = (expected_started_at + 6.days).end_of_day
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
          expect(subscription.subscription_instances.count).to eq(1)

          subscription_instance = subscription.subscription_instances.first
          expect(subscription_instance.status.to_sym).to eq(:active)
          expect(subscription_instance.total_amount).to eq(0)
        end

        travel_to(subscription_at + 1.week) do
          Subscriptions::BillingService.call
          perform_all_enqueued_jobs

          subscription = Subscription.find_by(external_id: "#{customer.external_id}_1")
          expect(subscription.subscription_instances.count).to eq(2) # 1 for the initial subscription instance and 1 for the new one

          finalized_subscription_instance = subscription.subscription_instances.where(status: :finalized).first
          expect(finalized_subscription_instance).to be_present
          # The total amount will be added to subscription instance at when the subscription instance is finalized
          expect(finalized_subscription_instance.total_amount).to eq(plan_in_arreas.amount_cents.fdiv(currency.subunit_to_unit))

          active_subscription_instance = subscription.subscription_instances.where(status: :active).first
          expect(active_subscription_instance).to be_present
          # The total amount of next subscription instance will be 0 because its plan is pay in arrears
          expect(active_subscription_instance.total_amount).to eq(0)

          expected_started_at = (subscription_at + 1.week).beginning_of_day
          expected_end_at = (expected_started_at + 6.days).end_of_day
          expect(active_subscription_instance.started_at.to_i).to eq(expected_started_at.to_i)
          expect(active_subscription_instance.ended_at.to_i).to eq(expected_end_at.to_i)
        end
      end
    end
  end

  # TODO implement the scenario when plan has base amount and usage charges
end
