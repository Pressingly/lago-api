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
  end
end
