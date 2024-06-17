# frozen_string_literal: true
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: revenue-subscription-charge.dto.proto

require 'google/protobuf'


descriptor_data = "\n%revenue-subscription-charge.dto.proto\x12\x07revenue\"\xce\x01\n\x1b\x43reateSubscriptionChargeReq\x12\x14\n\x0cpinetIdToken\x18\x01 \x01(\t\x12\x17\n\x0fmembershipOrgId\x18\x02 \x01(\t\x12\x1e\n\x16subscriptionInstanceId\x18\x03 \x01(\t\x12\x0e\n\x06\x61mount\x18\x04 \x01(\x05\x12\x10\n\x08\x66raction\x18\x05 \x01(\x05\x12\x14\n\x0c\x63urrencyCode\x18\x06 \x01(\t\x12\x18\n\x0b\x64\x65scription\x18\x07 \x01(\tH\x00\x88\x01\x01\x42\x0e\n\x0c_description\"\x8b\x01\n\x1bUpdateSubscriptionChargeReq\x12\x1c\n\x14subscriptionChargeId\x18\x01 \x01(\t\x12\x14\n\x0cpinetIdToken\x18\x02 \x01(\t\x12\x0e\n\x06\x61mount\x18\x03 \x01(\x05\x12\x18\n\x0b\x64\x65scription\x18\x04 \x01(\tH\x00\x88\x01\x01\x42\x0e\n\x0c_description\"\x9f\x01\n\x1d\x46inalizeSubscriptionChargeReq\x12\x1c\n\x14subscriptionChargeId\x18\x01 \x01(\t\x12\x0e\n\x06\x61mount\x18\x02 \x01(\x05\x12\x10\n\x08\x66raction\x18\x03 \x01(\x05\x12\x14\n\x0c\x63urrencyCode\x18\x04 \x01(\t\x12\x18\n\x0b\x64\x65scription\x18\x05 \x01(\tH\x00\x88\x01\x01\x42\x0e\n\x0c_description\"N\n&GetSubscriptionChargeContractStatusReq\x12$\n\x1csubscriptionChargeContractId\x18\x01 \x01(\t\"\xa4\x01\n#SubscriptionChargeContractStatusRes\x12\x1c\n\x14subscriptionChargeId\x18\x01 \x01(\t\x12$\n\x1csubscriptionChargeContractId\x18\x02 \x01(\t\x12\x39\n\x06status\x18\x03 \x01(\x0e\x32).revenue.SubscriptionChargeContractStatus\">\n\x1eGetSubscriptionChargeStatusReq\x12\x1c\n\x14subscriptionChargeId\x18\x01 \x01(\t\"n\n\x1bSubscriptionChargeStatusRes\x12\x1c\n\x14subscriptionChargeId\x18\x01 \x01(\t\x12\x31\n\x06status\x18\x02 \x01(\x0e\x32!.revenue.SubscriptionChargeStatus*\xbb\x01\n SubscriptionChargeContractStatus\x12\x33\n/SUBSCRIPTION_CHARGE_CONTRACT_STATUS_IN_PROGRESS\x10\x00\x12\x30\n,SUBSCRIPTION_CHARGE_CONTRACT_STATUS_APPROVED\x10\x01\x12\x30\n,SUBSCRIPTION_CHARGE_CONTRACT_STATUS_REJECTED\x10\x02*p\n\x18SubscriptionChargeStatus\x12*\n&SUBSCRIPTION_CHARGE_STATUS_IN_PROGRESS\x10\x00\x12(\n$SUBSCRIPTION_CHARGE_STATUS_FINALIZED\x10\x01\x62\x06proto3"

pool = Google::Protobuf::DescriptorPool.generated_pool
pool.add_serialized_file(descriptor_data)

module Revenue
  CreateSubscriptionChargeReq = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("revenue.CreateSubscriptionChargeReq").msgclass
  UpdateSubscriptionChargeReq = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("revenue.UpdateSubscriptionChargeReq").msgclass
  FinalizeSubscriptionChargeReq = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("revenue.FinalizeSubscriptionChargeReq").msgclass
  GetSubscriptionChargeContractStatusReq = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("revenue.GetSubscriptionChargeContractStatusReq").msgclass
  SubscriptionChargeContractStatusRes = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("revenue.SubscriptionChargeContractStatusRes").msgclass
  GetSubscriptionChargeStatusReq = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("revenue.GetSubscriptionChargeStatusReq").msgclass
  SubscriptionChargeStatusRes = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("revenue.SubscriptionChargeStatusRes").msgclass
  SubscriptionChargeContractStatus = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("revenue.SubscriptionChargeContractStatus").enummodule
  SubscriptionChargeStatus = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("revenue.SubscriptionChargeStatus").enummodule
end
