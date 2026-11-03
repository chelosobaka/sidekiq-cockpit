ENV['RAILS_ENV'] ||= 'test'
ENV['REDIS_URL'] ||= 'redis://localhost:6379/15'

require_relative 'dummy/config/environment'
require 'rspec/rails'

Sidekiq.logger.level = Logger::WARN

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.order = :random

  config.before do
    Sidekiq.redis(&:flushdb)
    SidekiqJobsDisplayer.reset_config!
  end
end
