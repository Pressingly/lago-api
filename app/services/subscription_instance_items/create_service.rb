# frozen_string_literal: true

module SubscriptionInstanceItems
  class CreateService < BaseService
    def initialize(subscription_instance:, fee_amount:, charge_type:, code: nil)
      @subscription_instance = subscription_instance
      @fee_amount = fee_amount
      @charge_type = charge_type
      @code = code

      super
    end

    def call
      result.subscription_instance_item = subscription_instance.subscription_instance_items.create!(
        fee_amount:,
        charge_type:,
        code:
      )

      result
    rescue ActiveRecord::RecordInvalid => e
      result.record_validation_failure!(record: e.record)
    rescue ArgumentError
      result.validation_failure!(errors: { charge_type: ['invalid_charge_type'] })
    end

    private

    attr_reader :subscription_instance, :fee_amount, :charge_type, :code
  end
end
