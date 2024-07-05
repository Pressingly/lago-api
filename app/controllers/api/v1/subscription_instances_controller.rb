# frozen_string_literal: true

module Api
  module V1
    class SubscriptionInstancesController < Api::BaseController
      def finalize
        subscription_instance = SubscriptionInstance.find_by(id: params[:id])

        return not_found_error(resource: 'subscription_instance') unless subscription_instance
        unless subscription_instance.active?
          return render_error_response(
            error: 'subscription_instance_not_active',
            message: 'Subscription instance is not active',
          )
        end

        result = SubscriptionCharges::FinalizeService.call(subscription_instance: subscription_instance)

        if result&.success?
          render_subscription_instance(subscription_instance.reload)
        else
          render_error_response(result)
        end
      end

      def show
        subscription_instance = SubscriptionInstance.find_by(id: params[:id])

        not_found_error(resource: 'subscription_instance') unless subscription_instance
        render_subscription_instance(subscription_instance)
      end

      private

      def render_subscription_instance(subscription_instance)
        render(
          json: ::V1::SubscriptionInstanceSerializer.new(
            subscription_instance,
            root_name: 'subscription_instance',
            includes: %i[subscription_instance_items],
          ),
        )
      end
    end
  end
end
