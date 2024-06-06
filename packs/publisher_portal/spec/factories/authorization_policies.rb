# frozen_string_literal: true

FactoryBot.define do
  factory :authorization_policy do
    cedar_policy_id { SecureRandom.base64(22 * 3 / 4).tr('=', '') }
    plan_id { create(:plan).id }
  end
end
