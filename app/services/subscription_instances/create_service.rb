# frozen_string_literal: true

module SubscriptionInstances
  class CreateService < BaseService
    INTERVALS_COINCIDE_WITH_SUBSCRIPTION_START = %i[
      weekly
      monthly
      yearly
      quarterly
    ]
    def initialize(subscription:)
      super

      @subscription = subscription
    end

    def call
      return result unless valid?(subscription:)

      ActiveRecord::Base.transaction do
        result.subscription_instance = create_subscription_instance

        if charge_without_usage && plan.amount_cents.positive? && plan.pay_in_advance?
          new_item_creation_result = create_new_subscription_instance_item(result.subscription_instance)
          if new_item_creation_result.success?
            subscription_instance_item = new_item_creation_result.subscription_instance_item

            result.subscription_instance = update_total_subscription_value(result.subscription_instance, subscription_instance_item.fee_amount_cents)
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

    attr_reader :subscription
    delegate :customer, :plan, to: :subscription

    def valid?(subscription:)
      return result.validation_failure!(errors: { subscription: ['is_not_active'] }) unless subscription.active?

      result
    end

    def create_subscription_instance
      new_subscription_instance = SubscriptionInstance.new(
        subscription:,
        started_at:,
        ended_at: nil,
        is_finalized: false,
        total_subscription_value: 0
      )

      begin
        new_subscription_instance.save!

        new_subscription_instance
      rescue ActiveRecord::RecordInvalid => e
        result.record_validation_failure!(record: e.record)
      end
    end

    def started_at
      return subscription.started_at if INTERVALS_COINCIDE_WITH_SUBSCRIPTION_START.include?(plan.interval.to_sym)

      nil
    end

    def ended_at
      # depend on billing time of subscription
      # how do i calculate the ending_at?
      # is there any existing service that can help me with this?
      # exmaple:
      # if subscrription.billing_time == 'anniversary' && plan.interval == 'weekly'
      #   ending_at = subscription.ending_at + 1.week
      # else
      #   ending_at = Time.current.end_of_week
      # end
    end

    def create_new_subscription_instance_item(subscription_instance)
      SubscriptionInstanceItems::CreateService.new(
        subscription_instance: subscription_instance,
        fee_amount_cents: plan.amount_cents,
        charge_type: SubscriptionInstanceItem.charge_types[:base_charge]
      ).call
    end

    def charge_without_usage
      # TODO: add new column to plan table
      return plan.charge_without_usage if plan.has_attribute?(:charge_without_usage)

      true
    end

    def update_total_subscription_value(subscription_instance, fee_amount_cents)
      prev_subscription_value = subscription_instance.total_subscription_value
      total_subscription_value = prev_subscription_value + fee_amount_cents.fdiv(100)

      if prev_subscription_value != total_subscription_value
        subscription_instance.update!(total_subscription_value: total_subscription_value)
      end

      subscription_instance
    end
  end
end
