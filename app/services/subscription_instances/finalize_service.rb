# frozen_string_literal: true

module SubscriptionInstances
  class FinalizeService < BaseService
    def initialize(subscription_instance:, subscription_fee:, charges_fees:)
      @subscription_instance = subscription_instance
      @subscription_fee = subscription_fee
      @charges_fees = charges_fees
      super
    end

    def call
      return result.validation_failure!(errors: { subscription_instance: ['is_not_active'] }) unless subscription_instance.active?

      ActiveRecord::Base.transaction do
        result.subscription_instance_items = create_subscription_instance_items
        result.subscription_instance = subscription_instance
        result
      end
    end

    private

    attr_reader :subscription_instance, :subscription_fee, :charges_fees
    delegate :subscription, to: :subscription_instance

    def create_subscription_instance_items
      subscription_instance_items = []
      subscription_instance_items += create_subscription_instance_items_for_charges_fees if charges_fees.present?
      subscription_instance_items << create_subscription_instance_item_for_subscription_fee if should_create_item_for_subscription_fee?

      subscription_instance_items
    end

    def create_subscription_instance_items_for_charges_fees
      charges_fees.map do |charge_fee|
        create_subscription_instance_item(
          fee_amount: charge_fee.amount,
          charge_type: :usage_charge,
          code: charge_fee.charge.billable_metric.code
        )
      end
    end

    def create_subscription_instance_item_for_subscription_fee
      create_subscription_instance_item(
        fee_amount: subscription_fee.amount,
        charge_type: :base_charge
      )
    end

    def create_subscription_instance_item(fee_amount:, charge_type:, code: nil)
      result = SubscriptionInstanceItems::CreateService.new(
        subscription_instance: subscription_instance,
        fee_amount: fee_amount.cents.fdiv(fee_amount.currency.subunit_to_unit),
        charge_type: SubscriptionInstanceItem.charge_types[charge_type],
        code: code
      ).call
      result.raise_if_error!
      result.subscription_instance_item
    end

    def should_create_item_for_subscription_fee?
      subscription.plan.pay_in_arrear? && subscription_fee&.amount_cents&.positive?
    end

    def total_amount
      @total_amount ||= @subscription_instance_items.sum(&:fee_amount)
    end

    def increase_total_amount
      result = SubscriptionInstances::IncreaseTotalValueService.new(
        subscription_instance: subscription_instance,
        fee_amount: total_amount
      ).call
      result.raise_if_error!
    end
  end
end
