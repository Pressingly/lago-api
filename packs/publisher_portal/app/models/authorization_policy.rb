class AuthorizationPolicy < PublisherPortalRecord
  validates :cedar_policy_id, presence: true
  validates :plan_id, presence: true
end
