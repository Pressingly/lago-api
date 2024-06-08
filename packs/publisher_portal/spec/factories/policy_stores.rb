# frozen_string_literal: true

FactoryBot.define do
  factory :policy_store do
    policy_store_id { SecureRandom.base64(22 * 3 / 4).tr('=', '') }
    namespace { 'ABCNews' }
    schema {
      {ABCNews: {entityTypes: {Subscriber: {shape: {attributes: {}, type: "Record"}, memberOfTypes: ["SubscriptionPlan"]},
                               ResourceGroup: {memberOfTypes: [], shape: {attributes: {}, type: "Record"}},
                               Article: {memberOfTypes: ["ResourceGroup"], shape: {type: "Record", attributes: {}}},
                               SubscriptionPlan: {memberOfTypes: [], shape: {type: "Record", attributes: {}}}},
                 actions: {Comment: {appliesTo: {context: {attributes: {}, type: "Record"},
                                                 principalTypes: ["SubscriptionPlan"],
                                                 resourceTypes: ["Article"]}},
                           Read: {memberOf: [],
                                  appliesTo: {principalTypes: ["Subscriber", "SubscriptionPlan"],
                                              context: {attributes: {}, type: "Record"},
                                              resourceTypes: ["Article", "ResourceGroup"]}},
                           Like: {memberOf: [{id: "Read"}],
                                  appliesTo: {principalTypes: ["SubscriptionPlan"],
                                              resourceTypes: ["Article"],
                                              context: {type: "Record", attributes: {}}}}}}}
    }
  end
end
