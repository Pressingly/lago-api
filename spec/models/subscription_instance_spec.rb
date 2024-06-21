# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubscriptionInstance, type: :model do
  let(:subscription) { create(:subscription) }

  describe 'creation' do
    let(:subscription_instance) { create(:subscription_instance, subscription:) }

    it 'is valid with valid attributes' do
      expect(subscription_instance).to be_valid
    end

    it 'is not valid without a subscription' do
      subscription_instance.subscription = nil
      expect(subscription_instance).not_to be_valid
    end
  end

  describe '#finalize' do
    let(:subscription_instance) { create(:subscription_instance, status: :active, subscription:) }

    before do
      # Freeze time to a known point for comparison
      Timecop.freeze(Time.current)
      subscription_instance.finalize!
    end

    after { Timecop.return }

    it 'changes the status to finalized' do
      expect(subscription_instance.status).to eq('finalized')
    end

    it 'sets ended_at to the current time if it was nil' do
      expect(subscription_instance.ended_at).to be_within(1.second).of(Time.current)
    end
  end
end
