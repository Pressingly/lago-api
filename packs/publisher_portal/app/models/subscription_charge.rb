class SubscriptionCharge < PublisherPortalRecord
  create_table :avp_policy_stores, id: :uuid do |t|
    t.string :avp_policy_store_id
    t.string :namespace
    t.json :schema

    t.timestamps
  end
end
