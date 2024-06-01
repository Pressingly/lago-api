module EntitlementAdapter
  class ConverterService < BaseService
    def initialize(payload:, policy_store_id:)
      @payload = payload
      @policy_store = PolicyStore.find_by(id: policy_store_id)

      @user_id = payload["userId"]
      super
    end

    def call
      result = {
        policy_store_id: get_policy_store_id,
        principal: {
          entity_type: principal_entity_type,
          entity_id: @user_id,
        },
        action: {
          action_type: action_type,
          action_id: get_payload_action,
        },
        resource: {
          entity_type: resource_entity_type,
          entity_id: resource_type,
        },
        context: {
          context_map: {}
        },
        entities: {
          entity_list: [
            {
              identifier: {
                entity_type: principal_entity_type,
                entity_id: @user_id,
              },
              parents: map_plans_to_principals
            },
            {
              identifier: {
                entity_type: article_entity_type,
                entity_id: resource_type,
              },
              parents: [
                {
                  entity_type: resource_entity_type,
                  entity_id: resource_type,
                }
              ]
            },
          ],
        },
      }

      Rails.logger.info("ConverterService result: #{result}")

      result
    end

    private

    attr_reader :payload
    attr_reader :policy_store_id

    def get_policy_store_id
      @policy_store.policy_store_id
    end

    def principal_entity_type
      "#{@policy_store.namespace}::Subscriber"
    end

    def subscription_plan_entity_type
      "#{@policy_store.namespace}::SubscriptionPlan"
    end

    def resource_entity_type
      "#{@policy_store.namespace}::ResourceGroup"
    end

    def article_entity_type
      "#{@policy_store.namespace}::Article"
    end

    def action_type
      "#{@policy_store.namespace}::Action"
    end

    def all_actions
      @policy_store.schema[@policy_store.namespace]["actions"].keys
    end

    def get_payload_action
      curr_action = @payload["actionName"]&.downcase
      all_actions.find { |action| action.downcase == curr_action }
    end

    def resource_id
      @payload["resource"]["id"]
    end

    def resource_type
      @payload["resource"]["type"]
    end

    def all_plans_by_user
      return [] if @user_id.nil?

      Plan.joins(:subscriptions).where(subscriptions: { customer_id: @user_id }).uniq
    end

    def map_plans_to_principals
      all_plans_by_user.map do |plan|
        {
          entity_type: subscription_plan_entity_type,
          entity_id: plan.id,
        }
      end
    end
  end
end
