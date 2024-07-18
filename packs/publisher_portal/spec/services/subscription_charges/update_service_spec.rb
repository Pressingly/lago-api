# frozen_string_literal: true

require 'rails_helper'
require 'revenue.service_services_pb'

RSpec.describe SubscriptionCharges::UpdateService do
  subject(:update_service) do
    described_class.new(
      subscription_instance: sub_instance,
      subscription_instance_item: sub_instance_item
    )
  end

  let(:subscription) { create(:subscription) }
  let(:sub_instance) { create(:subscription_instance, total_amount: 1) }
  let(:sub_instance_item) { create(:subscription_instance_item, subscription_instance: sub_instance, fee_amount: 0.1) }
  let(:organization) { create(:organization) }
  let(:plan) { create(:plan, organization: organization) }
  let(:stub) { instance_double(Revenue::RevenueGrpcService::Stub) }

  before do
    allow(SubscriptionInstance).to receive(:find_by).and_return(sub_instance)
    allow(Revenue::RevenueGrpcService::Stub).to receive(:new).and_return(stub)
    allow(stub).to receive(:update_subscription_charge).and_return(OpenStruct.new(status: 'approved'))
  end

  describe '#call' do
    it 'calls the update_subscription_charge method on the stub with the correct arguments' do
      expected_request = Revenue::UpdateSubscriptionChargeReq.new(
        amount: sub_instance.total_amount.to_f,
        description: plan.description,
        subscriptionChargeId: sub_instance.pinet_subscription_charge_id,
        subscriptionInstanceItemId: subscription_instance_item.id,
        pinetIdToken: customer.pinet_id_token,
        currencyCode: customer.currency,
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
