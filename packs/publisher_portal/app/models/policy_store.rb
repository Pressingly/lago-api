class PolicyStore < PublisherPortalRecord
  validates :namespace, presence: true
  validates :policy_store_id, presence: true
  validates :schema, presence: true
end
