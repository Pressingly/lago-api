module EntitlementAdapter
  class ConverterService < BaseService
    def initialize(payload:, policy_store_id:)
      @payload = payload
      @policy_store = PolicyStore.find_by(id: policy_store_id)

      @external_customer_id = payload["externalCustomerId"]
      super
    end

    def call
      result = {
        policy_store_id: get_policy_store_id,
        principal: {
          entity_type: principal_entity_type,
          entity_id: @external_customer_id,
        },
        action: {
          action_type: action_type,
          action_id: get_payload_action,
        },
        resource: {
          entity_type: article_entity_type,
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
                entity_id: @external_customer_id,
              },
              parents: map_plans_to_principals
            },
            {
              identifier: {
                entity_type: article_entity_type,
                entity_id: resource_type,
              },
              attributes: {
                category: {
                  string: resource_category
                }
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

    attr_reader :payload, :policy_store_id

    def namespace
      @namespace ||= @policy_store.namespace
    end

    def get_policy_store_id
      @policy_store.policy_store_id
    end

    def principal_entity_type
      "#{namespace}::Subscriber"
    end

    def subscription_plan_entity_type
      "#{namespace}::SubscriptionPlan"
    end

    def resource_entity_type
      "#{namespace}::ResourceGroup"
    end

    def article_entity_type
      "#{namespace}::Article"
    end

    def resource_category
      payload["resource"]["category"]
    end

    def action_type
      "#{namespace}::Action"
    end

    def all_actions
      @policy_store.schema[namespace]["actions"].keys
    end

    def get_payload_action
      curr_action = payload["actionName"]&.downcase
      all_actions.find { |action| action.downcase == curr_action }
    end

    def resource_id
      payload["resource"]["id"]
    end

    def resource_type
      payload["resource"]["type"]
    end

    def all_plans_by_user
      return [] if @external_customer_id.nil?

      customer_id = Customer.find_by(external_id: @external_customer_id)&.id

      Plan.joins(:subscriptions).where(subscriptions: { customer_id: customer_id }).uniq
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
