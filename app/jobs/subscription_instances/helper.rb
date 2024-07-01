# frozen_string_literal: true

module SubscriptionInstances
  module Helper
    private

    def should_create_subscription_charge?(result)
      subscription_instance = result.subscription_instance
      subscription_instance_item = result.subscription_instance_item

      subscription_instance.present? &&
        subscription_instance_item.present? &&
        subscription_instance_item.charge_type == SubscriptionInstanceItem.charge_types[:base_charge] &&
        subscription_instance_item.fee_amount.positive?
    end
  end
end
