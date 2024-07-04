# frozen_string_literal: true

module Events
  module Sync
    class PostProcessSyncService < PostProcessService
      private

      def handle_pay_in_advance
        return unless billable_metric

        charges.where(invoiceable: false).find_each do |charge|
          Fees::CreatePayInAdvanceJob.perform_now(charge:, event:)
        end

        # NOTE: ensure event is processable
        processable_event = billable_metric.count_agg? ||
          billable_metric.custom_agg? ||
          event.properties[billable_metric.field_name].present?
        return unless processable_event

        charges.where(invoiceable: true).find_each do |charge|
          Invoices::CreatePayInAdvanceChargeJob.perform_now(charge:, event:, timestamp: event.timestamp)
        end
      end
    end
  end
end
