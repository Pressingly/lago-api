# frozen_string_literal: true

require 'rails_helper'

describe 'Finalize Subscription Instance Scenario', :scenarios, type: :request do
  let(:organization) { create(:organization, webhook_url: nil, default_currency: 'USD') }
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

  let(:pdf_generator) { instance_double(Utils::PdfGenerator) }
  let(:pdf_file) { StringIO.new(File.read(Rails.root.join('spec/fixtures/blank.pdf'))) }
  let(:pdf_result) { OpenStruct.new(io: pdf_file) }

  before do
    allow(Utils::PdfGenerator).to receive(:new)
      .and_return(pdf_generator)
    allow(pdf_generator).to receive(:call)
      .and_return(pdf_result)
  end

  context 'when the subscription reaches its end billing period' do
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
          expect(subscription.subscription_instances.count).to eq(1)

          subscription_instance = subscription.subscription_instances.first
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
          expect(finalized_subscription_instance).to be_present

          # The total amount will include the base charge and the usage charge during the billing period
          expected_amount = plan_in_advance.amount_cents.fdiv(currency.subunit_to_unit) + BigDecimal(charge.properties['amount']) * number_of_events
          expect(finalized_subscription_instance.total_amount).to eq(expected_amount)
        end
      end
    end
  end

  context 'when terminate subscription via api' do
    it 'finalizes subscription instance correctly' do
      jul5 = DateTime.new(2024, 7, 5)
      travel_to(jul5) do
        create_subscription(
          external_customer_id: customer.external_id,
          external_id: "#{customer.external_id}_1",
          plan_code: plan_in_advance.code,
          billing_time: :anniversary,
          subscription_at: jul5.iso8601
        )

        subscription = Subscription.find_by(external_id: "#{customer.external_id}_1")
        expect(subscription.subscription_instances.count).to eq(1)

        terminate_subscription(subscription)

        subscription_instance = subscription.subscription_instances.first
        expect(subscription_instance.status.to_sym).to eq(:finalized)
        expect(subscription.subscription_instances.count).to eq(1)
      end
    end
  end

  context 'when the subscription reaches its ending date' do
    let(:creation_time) { DateTime.new(2024, 7, 5, 0, 0) }
    let(:subscription_at) { DateTime.new(2024, 7, 5, 0, 0) }
    let(:ending_at) { DateTime.new(2024, 7, 6, 0, 0) }

    it 'finalizes subscription instance correctly' do
      subscription = nil
      subscription_instance = nil
      travel_to(creation_time) do
        create_subscription(
          external_customer_id: customer.external_id,
          external_id: "#{customer.external_id}_1",
          plan_code: plan_in_advance.code,
          billing_time: :anniversary,
          subscription_at: subscription_at.iso8601,
          ending_at: ending_at.iso8601
        )

        subscription = Subscription.find_by(external_id: "#{customer.external_id}_1")
        subscription_instance = subscription.subscription_instances.first

        expect(subscription_instance.status.to_sym).to eq(:active)
      end

      travel_to(ending_at + 15.minutes) do
        Clock::TerminateEndedSubscriptionsJob.perform_now
        perform_all_enqueued_jobs

        subscription_instance.reload
        subscription.reload
        expect(subscription_instance.status.to_sym).to eq(:finalized)
        expect(subscription.subscription_instances.count).to eq(1)
      end
    end
  end
end
