require 'sidekiq'
require 'sidekiq-cron'

require 'sidekiq_jobs_displayer/version'
require 'sidekiq_jobs_displayer/configuration'
require 'sidekiq_jobs_displayer/history'
require 'sidekiq_jobs_displayer/middleware'
require 'sidekiq_jobs_displayer/overview'
require 'sidekiq_jobs_displayer/engine'

# Своя страница фоновых задач вместо дашборда Sidekiq.
#
# Подключение:
#   # config/routes.rb
#   mount SidekiqJobsDisplayer::Engine => '/admin/jobs'
#
#   # config/initializers/sidekiq_jobs_displayer.rb (rails g sidekiq_jobs_displayer:install)
#   SidekiqJobsDisplayer.configure do |config|
#     config.authorize = ->(controller) { controller.current_user&.admin? }
#   end
#
# Middleware истории запусков встаёт в цепочку Sidekiq сама (см. Engine), если
# config.install_middleware не выключен.
module SidekiqJobsDisplayer
  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield config
    end

    def reset_config!
      @config = Configuration.new
    end
  end
end
