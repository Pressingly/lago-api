# frozen_string_literal: true

class SubscriptionInstance < ApplicationRecord
  include PaperTrailTraceable

  belongs_to :subscription
end
