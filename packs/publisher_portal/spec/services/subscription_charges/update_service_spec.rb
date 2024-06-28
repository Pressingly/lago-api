# frozen_string_literal: true

require 'rails_helper'
require 'revenue.service_services_pb'

RSpec.describe SubscriptionCharges::UpdateService do
  subject(:update_service) { described_class.new(subscription_instance: sub_instance) }

  let(:subscription) { create(:subscription) }
  let(:sub_instance) { create(:subscription_instance) }
  let(:organization) { create(:organization) }
  let(:plan) { create(:plan, organization: organization) }
  let(:stub) { instance_double(Revenue::RevenueGrpcService::Stub) }

  before do
    allow(SubscriptionInstance).to receive(:find_by).and_return(sub_instance)
    allow(Revenue::RevenueGrpcService::Stub).to receive(:new).and_return(stub)
    allow(stub).to receive(:update_subscription_charge)
  end

  describe '#call' do
    it 'calls the update_subscription_charge method on the stub with the correct arguments' do
      expected_request = Revenue::UpdateSubscriptionChargeReq.new(
        amount: sub_instance.total_amount.to_f,
        versionNumber: sub_instance.version_number,
        description: plan.description,
        subscriptionChargeId: sub_instance.pinet_subscription_charge_id,
      )

      update_service.call

      expect(stub).to have_received(:update_subscription_charge).with(expected_request)
    end

    context 'when an error occurs' do
      before do
        allow(stub)
          .to receive(:update_subscription_charge)
          .and_raise(GRPC::BadStatus.new(GRPC::Core::StatusCodes::UNKNOWN, 'Error updating subscription charge:'))
      end

      it 'raises a StandardError' do
        expect { update_service.call }.to raise_error(StandardError, /Error updating subscription charge/)
      end
    end
  end
end
