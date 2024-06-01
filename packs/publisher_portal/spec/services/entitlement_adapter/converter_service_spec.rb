# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EntitlementAdapter::ConverterService, type: :service do
  subject(:converter_service) { described_class.new(payload:, policy_store_id:) }

  let(:base_payload) {
    {"userId" => "012646d9-1b82-43e3-8ef9-60c538091149",
     "publisherId" => "Publisher id we create for the publisher when they are onboarded",
     "actionName" => "read",
     "context" => {},
     "resource" => {"id" => "2fc41fd4-70fd-4b23-95bc-bb3a98af2f9d",
                    "name" => "Liverpool is winning Champion League",
                    "type" => "article",
                    "author" => "author name",
                    "tags" => ["Climate change"],
                    "category" => "basketball"},
     "timestamp" => "2022-03-01T12:34:56+02:00"}
  }
  let(:policy_store) { create(:policy_store) }
  let(:policy_store_id) { policy_store.id }
  let(:payload) { base_payload }

  describe '#call' do
    before do
      payload
      policy_store
    end

    context 'when userId exist' do
      it 'principal entity id is the same with userId in payload' do
        result = converter_service.call
        aggregate_failures do
          expect(result[:principal][:entity_id]).to eq("012646d9-1b82-43e3-8ef9-60c538091149")
        end
      end
    end

    context 'when userId does not exist' do
      let(:payload) { base_payload.except("userId") }

      it 'principal entity id is nil' do
        result = converter_service.call
        aggregate_failures do
          expect(result[:principal][:entity_id]).to be_nil
        end
      end
    end

    context 'when actionName exist' do
      it 'action id is the same with actionName in payload' do
        result = converter_service.call
        aggregate_failures do
          expect(result[:action][:action_id]).to eq("Read")
        end
      end
    end

    context 'when actionName does not exist' do
      let(:payload) { base_payload.except("actionName") }

      it 'action id is nil' do
        result = converter_service.call
        aggregate_failures do
          expect(result[:action][:action_id]).to be_nil
        end
      end
    end

    context 'when resource id exists' do
      it 'resource id is the same with resource["id"] in payload' do
        result = converter_service.call
        aggregate_failures do
          expect(result[:resource][:entity_id]).to eq("article")
        end
      end
    end

    context 'when resource id does not exist' do
      let(:payload) { base_payload }

      it 'resource id is nil' do
        payload["resource"].delete("type")

        result = converter_service.call
        aggregate_failures do
          expect(result[:resource][:entity_id]).to be_nil
        end
      end
    end
  end
end
