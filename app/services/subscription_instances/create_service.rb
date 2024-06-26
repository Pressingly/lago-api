# frozen_string_literal: true

module SubscriptionInstances
  class CreateService < BaseService
    def initialize(subscription:, started_at:, ended_at:)
      @subscription = subscription
      @started_at = started_at
      @ended_at = ended_at

      super
    end

    def call
      return result.validation_failure!(errors: { subscription: ['is_not_active'] }) unless subscription.active?

      ActiveRecord::Base.transaction do
        result.subscription_instance = create_subscription_instance

        if charge_without_usage && plan.amount_cents.positive? && plan.pay_in_advance?
          new_item_creation_result = create_new_subscription_instance_item(result.subscription_instance)
          if new_item_creation_result.success?
            subscription_instance_item = new_item_creation_result.subscription_instance_item

            result.subscription_instance = update_total_amount(
              result.subscription_instance,
              subscription_instance_item.fee_amount
            )
          end
        end
      end

      result
    rescue ActiveRecord::RecordInvalid => e
      result.record_validation_failure!(record: e.record)
    rescue BaseService::FailedResult => e
      e.result
    end

    private

    attr_reader :subscription, :started_at, :ended_at
    delegate :customer, :plan, to: :subscription
    def create_subscription_instance
      new_subscription_instance = SubscriptionInstance.new(
        subscription:,
        started_at:,
        ended_at:,
        status: SubscriptionInstance.statuses[:active],
        total_amount: 0.0
      )

      begin
        new_subscription_instance.save!

        new_subscription_instance
      rescue ActiveRecord::RecordInvalid => e
        result.record_validation_failure!(record: e.record)
      end
    end

    def create_new_subscription_instance_item(subscription_instance)
      currency = plan.amount.currency
      SubscriptionInstanceItems::CreateService.new(
        subscription_instance: subscription_instance,
        fee_amount: plan.amount_cents.fdiv(currency.subunit_to_unit),
        charge_type: SubscriptionInstanceItem.charge_types[:base_charge]
      ).call
    end

    def charge_without_usage
      # TODO: add new column to plan table
      return plan.charge_without_usage if plan.has_attribute?(:charge_without_usage)

      true
    end

    def update_total_amount(subscription_instance, fees_amount)
      update_result = SubscriptionInstances::IncreaseTotalValueService.new(
        subscription_instance: subscription_instance,
        fee_amount: fees_amount
      ).call

      update_result.raise_if_error!
      update_result.subscription_instance
    end
  end
end
