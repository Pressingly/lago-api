# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubscriptionInstanceItem, type: :model do
  subject(:subscription_instance_item) { create(:subscription_instance_item, subscription_instance:, charge_type:, code:) }

  let(:subscription_instance) { create(:subscription_instance) }
  let(:charge_type) { 'base_charge' }
  let(:code) { nil }

  it 'is valid with valid attributes' do
    expect(subscription_instance_item).to be_valid
  end

  it 'is not valid without a charge_type' do
    subscription_instance_item.charge_type = nil
    expect(subscription_instance_item).not_to be_valid
  end

  context 'when charge_type is usage_charge' do
    let(:charge_type) { 'usage_charge' }
    let(:code) { 'valid_code' }

    it 'is valid with a code' do
      expect(subscription_instance_item).to be_valid
    end

    it 'is not valid without a code' do
      subscription_instance_item.code = nil
      expect(subscription_instance_item).not_to be_valid
    end
  end

  context 'when charge_type is base_charge' do
    let(:charge_type) { 'base_charge' }
    let(:code) { nil }

    it 'is valid without a code' do
      expect(subscription_instance_item).to be_valid
    end
  end
end
