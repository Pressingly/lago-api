# frozen_string_literal: true

module SubscriptionInstances
  class IncreaseTotalValueService < BaseService
    def initialize(subscription_instance:, fee_amount:)
      @subscription_instance = subscription_instance
      @fee_amount = fee_amount

      super
    end

    def call
      return unless fee_amount.positive?

      ActiveRecord::Base.transaction do
        # subscription_instance.lock!
        subscription_instance.total_amount += fee_amount
        subscription_instance.save!

        result.subscription_instance = subscription_instance.reload
      end

      result
    rescue ActiveRecord::RecordInvalid => e
      result.record_validation_failure!(record: e.record)
    end

    private

    attr_reader :subscription_instance, :fee_amount
  end
end
