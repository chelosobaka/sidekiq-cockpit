ENV['RAILS_ENV'] ||= 'test'
ENV['REDIS_URL'] ||= 'redis://localhost:6379/15'

require_relative 'dummy/config/environment'
require 'rspec/rails'
require 'sidekiq/api'

Sidekiq.logger.level = Logger::WARN

CRON = SidekiqJobsDisplayer::Schedulers::SidekiqCron.available?
warn "sidekiq-cron: #{CRON ? 'подключён' : 'нет'}"

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.order = :random
  config.filter_run_excluding(cron: true) unless CRON
  config.filter_run_excluding(cron: false) if CRON

  config.before do
    Sidekiq.redis(&:flushdb)
    SidekiqJobsDisplayer.reset_config!
    SidekiqJobsDisplayer.config.authorize { true }
  end
end

def build_run(**attrs)
  SidekiqJobsDisplayer::Stores::Runs::Run.new(
    jid: SecureRandom.hex(12), job_class: 'BackupJob', queue: 'default', started_at: Time.current, duration: 0.5,
    status: 'ok', error_class: nil, error_message: nil, args: '[]', retry_count: nil, **attrs
  )
end

def create_cron(name: 'backup', klass: 'BackupJob', cron: '0 0,12 * * * Europe/Moscow', **attrs)
  Sidekiq::Cron::Job.create(name: name, cron: cron, class: klass, **attrs)
end
