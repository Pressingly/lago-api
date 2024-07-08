# frozen_string_literal: true

require 'grpc' 
require_relative 'packs/publisher_portal/lib/auth_token_services_pb'
require_relative 'app/services/grpc/server/auth_token_service'
class GRPCServer
  def self.start
    s = GRPC::RpcServer.new
    s.add_http2_port('0.0.0.0:50051', :this_port_is_insecure)
    s.handle(Grpc::Server::AuthTokenService)
    puts 'gRPC Server running on port 50051'
    s.run_till_terminated
  end
end

GRPCServer.start if __FILE__ == $PROGRAM_NAME