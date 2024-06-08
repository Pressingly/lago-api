# frozen_string_literal: true

class SubscriptionInstance < ApplicationRecord
  include PaperTrailTraceable

  belongs_to :subscription
  has_many :subscription_instance_items, dependent: :destroy
end
