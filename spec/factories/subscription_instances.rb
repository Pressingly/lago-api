# frozen_string_literal: true

FactoryBot.define do
  factory :subscription_instance do
    subscription
    version_number { 0 }
    status { 'active' }
    started_at { Time.zone.now.beginning_of_month }
  end
end
