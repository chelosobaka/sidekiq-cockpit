require 'rails'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'active_job/railtie'

# Прогон с sidekiq-cron или без него — по тому, есть ли гем в бандле.
begin
  require 'sidekiq-cron'
rescue LoadError
  nil
end

require 'sidekiq_jobs_displayer'

module Dummy
  class Application < Rails::Application
    config.root = File.expand_path('..', __dir__)
    config.load_defaults Rails::VERSION::STRING.to_f
    config.eager_load = false
    config.secret_key_base = 'dummy'
    config.i18n.default_locale = :ru
    config.time_zone = 'Europe/Moscow'
    config.hosts.clear
    config.action_controller.allow_forgery_protection = false
    config.active_job.queue_adapter = :sidekiq
    config.logger = Logger.new(nil)
  end
end
