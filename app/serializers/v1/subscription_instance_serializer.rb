# frozen_string_literal: true

module V1
  class SubscriptionInstanceSerializer < ModelSerializer
    def serialize
      payload = {
        lago_id: model.id,
        subscription_id: model.subscription_id,
        started_at: model.started_at&.iso8601,
        ended_at: model.ended_at&.iso8601,
        pinet_subscription_charge_id: model.pinet_subscription_charge_id,
        total_amount: model.total_amount,
        status: model.status,
        created_at: model.created_at.iso8601,
      }

      payload = payload.merge(subscription_instance_items) if include?(:subscription_instance_items)
      payload
    end

    private

    def subscription_instance_items
      ::CollectionSerializer.new(
        model.subscription_instance_items,
        ::V1::SubscriptionInstanceItemSerializer,
        collection_name: 'subscription_instance_items',
      ).serialize
    end
  end
end
