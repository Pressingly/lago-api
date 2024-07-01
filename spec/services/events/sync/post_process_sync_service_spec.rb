# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Events::Sync::PostProcessSyncService, type: :service do
  subject(:process_service) { described_class.new(event:) }

  let(:organization) { create(:organization) }
  let(:customer) { create(:customer, organization:) }
  let(:plan) { create(:plan, organization:) }
  let(:subscription) { create(:subscription, organization:, customer:, plan:, started_at:) }
  let(:billable_metric) { create(:billable_metric, organization:) }

  let(:started_at) { Time.current - 3.days }
  let(:external_customer_id) { customer.external_id }
  let(:external_subscription_id) { subscription.external_id }
  let(:code) { billable_metric&.code }
  let(:timestamp) { Time.current - 1.second }
  let(:event_properties) { {} }

  let(:event) do
    create(
      :event,
      organization_id: organization.id,
      external_customer_id:,
      external_subscription_id:,
      timestamp:,
      code:,
      properties: event_properties,
    )
  end

  describe '#call' do
    before do
      allow(Fees::CreatePayInAdvanceJob).to receive(:perform_now)
      allow(Invoices::CreatePayInAdvanceChargeJob).to receive(:perform_now)
    end

    context 'when event matches an pay_in_advance charge that is not invoiceable' do
      let(:charge) { create(:standard_charge, :pay_in_advance, plan:, billable_metric:, invoiceable: false) }
      let(:billable_metric) do
        create(:billable_metric, organization:, aggregation_type: 'sum_agg', field_name: 'item_id')
      end

      let(:event_properties) { { billable_metric.field_name => '12' } }

      before { charge }

      it 'triggers a job to perform pay_in_advance aggregation immediately' do
        process_service.call
        expect(Fees::CreatePayInAdvanceJob).to have_received(:perform_now)
      end

      context 'when charge is invoiceable' do
        before { charge.update!(invoiceable: true) }

        it 'does not trigger a job to perform pay_in_advance aggregation immediately' do
          process_service.call
          expect(Fees::CreatePayInAdvanceJob).not_to have_received(:perform_now)
        end
      end

      context 'when multiple charges have the billable metric' do
        before { create(:standard_charge, :pay_in_advance, plan:, billable_metric:, invoiceable: false) }

        it 'triggers a job for each charge immediately' do
          process_service.call
          expect(Fees::CreatePayInAdvanceJob).to have_received(:perform_now).twice
        end
      end
    end

    context 'when event matches a pay_in_advance charge that is invoiceable' do
      let(:charge) { create(:standard_charge, :pay_in_advance, plan:, billable_metric:, invoiceable: true) }
      let(:billable_metric) do
        create(:billable_metric, organization:, aggregation_type: 'sum_agg', field_name: 'item_id')
      end

      let(:event_properties) { { billable_metric.field_name => '12' } }

      before { charge }

      it 'triggers a job to create the pay_in_advance charge invoice immediately' do
        process_service.call
        expect(Invoices::CreatePayInAdvanceChargeJob).to have_received(:perform_now)
      end

      context 'when charge is not invoiceable' do
        before { charge.update!(invoiceable: false) }

        it 'does not trigger a job to create the pay_in_advance charge invoice' do
          process_service.call
          expect(Invoices::CreatePayInAdvanceChargeJob).not_to have_received(:perform_now)
        end
      end

      context 'when multiple charges have the billable metric' do
        before { create(:standard_charge, :pay_in_advance, plan:, billable_metric:, invoiceable: true) }

        it 'triggers a job for each charge immediately' do
          process_service.call
          expect(Invoices::CreatePayInAdvanceChargeJob).to have_received(:perform_now).twice
        end
      end

      context 'when value for sum_agg is negative' do
        let(:event_properties) { { billable_metric.field_name => '-5' } }

        it 'triggers a job to perform immediately' do
          process_service.call
          expect(Invoices::CreatePayInAdvanceChargeJob).to have_received(:perform_now)
        end
      end

      context 'when event field name does not batch the BM one' do
        let(:event_properties) { { 'wrong_field_name' => '-5' } }

        it 'triggers a job' do
          process_service.call
          expect(Invoices::CreatePayInAdvanceChargeJob).not_to have_received(:perform_now)
        end
      end
    end
  end
end
