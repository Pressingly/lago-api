require 'rails_helper'

RSpec.describe Authorization::AuthorizeValidator, type: :model do
  let(:valid_attributes) do
    {
      externalCustomerId: 'user1',
      publisherId: 'publisher1',
      actionName: 'action1',
      context: {},
      resource: { 'id' => 'resource1', 'type' => 'type1' },
      timestamp: Time.current
    }
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      validator = described_class.new(valid_attributes)
      expect(validator).to be_valid
    end

    it 'is not valid without a user_id' do
      validator = described_class.new(valid_attributes.except(:externalCustomerId))
      expect(validator).not_to be_valid
    end

    it 'is not valid without a publisher_id' do
      validator = described_class.new(valid_attributes.except(:publisherId))
      expect(validator).not_to be_valid
    end

    it 'is not valid without an action_name' do
      validator = described_class.new(valid_attributes.except(:actionName))
      expect(validator).not_to be_valid
    end

    it 'is not valid without a timestamp' do
      validator = described_class.new(valid_attributes.except(:timestamp))
      expect(validator).not_to be_valid
    end

    it 'is not valid without a resource' do
      validator = described_class.new(valid_attributes.merge(resource: {}))
      expect(validator).not_to be_valid
    end

    it 'is not valid without a resource id' do
      validator = described_class.new(valid_attributes.merge(resource: { 'type' => 'type1' }))
      expect(validator).not_to be_valid
    end

    it 'is not valid without a resource type' do
      validator = described_class.new(valid_attributes.merge(resource: { 'id' => 'resource1' }))
      expect(validator).not_to be_valid
    end
  end
end
