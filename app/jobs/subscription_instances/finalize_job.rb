# frozen_string_literal: true

module SubscriptionInstances
  class FinalizeJob < ApplicationJob
    queue_as 'billing'

    def perform(subscription_instance:, subscription_fee:, charges_fees:)
      result = SubscriptionInstances::FinalizeService.new(
        subscription_instance: subscription_instance,
        subscription_fee: subscription_fee,
        charges_fees: charges_fees
      ).call

      result.raise_if_error!
      # TODO: Call service to finalize subscription charge
    end
  end
end
