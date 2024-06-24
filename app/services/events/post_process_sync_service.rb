# frozen_string_literal: true

module Events
  class PostProcessSyncService < PostProcessService
    private

    def handle_pay_in_advance
      return unless billable_metric

      charges.where(invoiceable: false).find_each do |charge|
        # TODO: understand what this does, do we need sync for pay in advance?
        Fees::CreatePayInAdvanceJob.perform_now(charge:, event:)
      end

      # NOTE: ensure event is processable
      processable_event = billable_metric.count_agg? ||
        billable_metric.custom_agg? ||
        event.properties[billable_metric.field_name].present?
      return unless processable_event

      charges.where(invoiceable: true).find_each do |charge|
        result = Invoices::CreatePayInAdvanceChargeService.call(charge:, event:, timestamp: event.timestamp)
        result.raise_if_error!
      end
    end
  end
end
