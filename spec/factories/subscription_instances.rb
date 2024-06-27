# frozen_string_literal: true

FactoryBot.define do
  factory :subscription_instance do
    subscription
    version_number { 0 }
    status { 'active' }

    after(:build) do |subscription_instance|
      subscription_instance.started_at = subscription_instance.subscription.started_at
    end
  end
end
