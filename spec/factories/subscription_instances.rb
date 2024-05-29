# frozen_string_literal: true

FactoryBot.define do
  factory :subscription_instance do
    subscription

    is_finalized { false }
  end
end
