# frozen_string_literal: true

FactoryBot.define do
  factory :subscription_instance do
    subscription
    version_number { 0 }
    status { 'active' }
  end
end
