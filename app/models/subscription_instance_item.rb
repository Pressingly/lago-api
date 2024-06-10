class SubscriptionInstanceItem < ApplicationRecord
  include PaperTrailTraceable

  belongs_to :subscription_instance

  CHARGE_TYPES = {
    base_charge: 'base_charge',
    usage_charge: 'usage_charge',
  }.freeze

  enum charge_type: CHARGE_TYPES

  validates :code, presence: true, if: :usage_charge?
  validates :charge_type, presence: true, inclusion: {in: CHARGE_TYPES.keys.map(&:to_s)}
end
