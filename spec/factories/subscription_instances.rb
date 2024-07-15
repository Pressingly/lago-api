# frozen_string_literal: true

FactoryBot.define do
  factory :subscription_instance do
    subscription
    status { 'active' }
    started_at { Time.zone.now.beginning_of_month }
  end
end
