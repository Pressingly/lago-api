FactoryBot.define do
  factory :subscription_instance_item do
    subscription_instance
    fee_amount { 0 }
    charge_type { "base_charge" }
    code { nil }
  end
end
