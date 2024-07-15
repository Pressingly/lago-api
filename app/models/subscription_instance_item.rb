class SubscriptionInstanceItem < ApplicationRecord
  include PaperTrailTraceable
  include AASM

  belongs_to :subscription_instance

  CHARGE_TYPES = {
    base_charge: 'base_charge',
    usage_charge: 'usage_charge',
  }.freeze

  CONTRACT_STATUS = {
    pending: 'pending',
    approved: 'approved',
    rejected: 'rejected',
    failed: 'failed'
  }.freeze

  enum charge_type: CHARGE_TYPES
  enum contract_status: CONTRACT_STATUS

  aasm column: 'contract_status', timestamp: true do
    state :pending, initial: true
    state :approved
    state :rejected
    state :failed

    event :approve do
      transitions from: :pending, to: :approved
    end

    event :reject do
      transitions from: :pending, to: :rejected
    end
  end

  validates :code, presence: true, if: :usage_charge?
  validates :charge_type, presence: true, inclusion: {in: CHARGE_TYPES.keys.map(&:to_s)}
end
