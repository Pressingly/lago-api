# frozen_string_literal: true

redis_url = ENV['REDIS_URL']
redis_config = {
  url: redis_url,
  pool_timeout: 5,
  ssl_params: {
    verify_mode: OpenSSL::SSL::VERIFY_NONE,
  }
}

if ENV['LAGO_SIDEKIQ_WEB'] == 'true'
  require 'sidekiq/web'
  Sidekiq::Web.use(ActionDispatch::Cookies)
  Sidekiq::Web.use(ActionDispatch::Session::CookieStore, key: '_interslice_session')
end

Sidekiq.configure_server do |config|
  config.redis = redis_config
  config.logger = Sidekiq::Logger.new($stdout)
  config.logger.formatter = Sidekiq::Logger::Formatters::JSON.new
  config[:max_retries] = 0
  config[:dead_max_jobs] = ENV.fetch('LAGO_SIDEKIQ_MAX_DEAD_JOBS', 100_000).to_i
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
  config.logger = Sidekiq::Logger.new($stdout)
  config.logger.formatter = Sidekiq::Logger::Formatters::JSON.new
end
