# frozen_string_literal: true

class SubscriptionInstance < ApplicationRecord
  include PaperTrailTraceable
  include AASM

  belongs_to :subscription
  has_many :subscription_instance_items, dependent: :destroy

  STATUSES = {
    pending: 'pending',
    active: 'active',
    finalized: 'finalized'
  }.freeze

  enum status: STATUSES

  aasm column: 'status', timestamps: true do
    state :pending, initial: true
    state :active
    state :finalized

    event :finalize do
      before do
        self.ended_at = Time.current if ended_at.nil?
      end
      transitions from: :active, to: :finalized
    end
  end
end
