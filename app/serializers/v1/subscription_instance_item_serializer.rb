# frozen_string_literal: true

module V1
  class SubscriptionInstanceItemSerializer < ModelSerializer
    def serialize
      {
        lago_id: model.id,
        subscription_instance_id: model.subscription_instance_id,
        contract_status: model.contract_status,
        fee_amount: model.fee_amount,
        charge_type: model.charge_type,
        code: model.code,
        created_at: model.created_at.iso8601,
      }
    end
  end
end
