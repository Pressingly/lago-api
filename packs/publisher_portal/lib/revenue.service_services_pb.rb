# Generated by the protocol buffer compiler.  DO NOT EDIT!
# Source: revenue.service.proto for package 'revenue'

require 'grpc'
require 'revenue.service_pb'

module Revenue
  module RevenueGrpcService
    class Service

      include ::GRPC::GenericService

      self.marshal_class_method = :encode
      self.unmarshal_class_method = :decode
      self.service_name = 'revenue.RevenueGrpcService'

      rpc :CreateSubscriptionCharge, ::Revenue::CreateSubscriptionChargeReq, ::Revenue::SubscriptionChargeContractStatusRes
      rpc :UpdateSubscriptionCharge, ::Revenue::UpdateSubscriptionChargeReq, ::Revenue::SubscriptionChargeContractStatusRes
      rpc :FinalizeSubscriptionCharge, ::Revenue::FinalizeSubscriptionChargeReq, ::Revenue::SubscriptionChargeContractStatusRes
      rpc :GetSubscriptionChargeContractStatus, ::Revenue::GetSubscriptionChargeContractStatusReq, ::Revenue::SubscriptionChargeContractStatusRes
      rpc :GetSubscriptionChargeStatus, ::Revenue::GetSubscriptionChargeStatusReq, ::Revenue::SubscriptionChargeStatusRes
    end

    Stub = Service.rpc_stub_class
  end
end
