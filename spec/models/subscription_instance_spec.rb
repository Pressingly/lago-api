# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubscriptionInstance, type: :model do
  subject(:subscription_instance) { create(:subscription_instance, subscription:) }

  let(:subscription) { create(:subscription) }

  it 'is valid with valid attributes' do
    expect(subscription_instance).to be_valid
  end

  it 'is not valid without a subscription' do
    subscription_instance.subscription = nil
    expect(subscription_instance).not_to be_valid
  end
end
