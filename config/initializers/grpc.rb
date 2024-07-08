require_relative '../../packs/publisher_portal/lib/auth_token_services_pb'
require_relative '../../app/services/grpc/server/auth_token_service'

Thread.new do # rubocop:disable ThreadSafety/NewThread
  s = GRPC::RpcServer.new
  s.add_http2_port(ENV['GRPC_HOST'] + ":" + ENV['GRPC_PORT'], :this_port_is_insecure)
  s.handle(Grpc::Server::AuthTokenService)
  s.run_till_terminated
end
