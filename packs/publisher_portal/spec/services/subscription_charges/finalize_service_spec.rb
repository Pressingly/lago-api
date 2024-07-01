# frozen_string_literal: true

require 'rails_helper'
require 'revenue.service_services_pb'

RSpec.describe SubscriptionCharges::FinalizeService do
  subject(:finalize_service) { described_class.new(subscription_instance: sub_instance) }

  let(:subscription) { create(:subscription) }
  let(:sub_instance) { create(:subscription_instance) }
  let(:customer) { create(:customer) }
  let(:organization) { create(:organization) }
  let(:plan) { create(:plan, organization: organization) }
  let(:stub) { instance_double(Revenue::RevenueGrpcService::Stub) }

  before do
    allow(SubscriptionInstance).to receive(:find_by).and_return(sub_instance)
    allow(Customer).to receive(:find_by).and_return(customer)
    allow(Plan).to receive(:find_by).and_return(plan)
    allow(Revenue::RevenueGrpcService::Stub).to receive(:new).and_return(stub)
    allow(stub).to receive(:finalize_subscription_charge)
  end

  describe '#call' do
    it 'calls the finalize_subscription_charge method on the stub with the correct arguments' do
      expected_request = Revenue::FinalizeSubscriptionChargeReq.new(
        subscriptionChargeId: sub_instance.pinet_subscription_charge_id,
        versionNumber: sub_instance.version_number,
        amount: sub_instance.total_amount.to_f,
        currencyCode: customer.currency,
        description: plan.description,
      )

      finalize_service.call

      expect(stub).to have_received(:finalize_subscription_charge).with(expected_request)
    end

    context 'when an error occurs' do
      before do
        allow(stub)
          .to receive(:finalize_subscription_charge)
          .and_raise(GRPC::BadStatus.new(
            GRPC::Core::StatusCodes::UNKNOWN, 'Error finalize subscription charge:'
          ))
      end

      it 'raises a StandardError' do
        expect { finalize_service.call }.to raise_error(StandardError, /Error finalize subscription charge/)
      end
    end
  end
end
