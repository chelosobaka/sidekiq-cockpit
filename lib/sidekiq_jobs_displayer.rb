require 'sidekiq'
require 'active_support'
require 'active_support/core_ext'

require 'sidekiq_jobs_displayer/version'

module SidekiqJobsDisplayer
  class Error < StandardError; end
end

require 'sidekiq_jobs_displayer/configuration'
require 'sidekiq_jobs_displayer/dsl'
require 'sidekiq_jobs_displayer/job_definition'
require 'sidekiq_jobs_displayer/schedulers/base'
require 'sidekiq_jobs_displayer/schedulers/none'
require 'sidekiq_jobs_displayer/schedulers/sidekiq_cron'
require 'sidekiq_jobs_displayer/schedulers'
require 'sidekiq_jobs_displayer/stores/redis_store'
require 'sidekiq_jobs_displayer/stores/runs'
require 'sidekiq_jobs_displayer/registry'
require 'sidekiq_jobs_displayer/middleware/recorder'
require 'sidekiq_jobs_displayer/log_sources'
require 'sidekiq_jobs_displayer/queries/overview'
require 'sidekiq_jobs_displayer/queries/job_details'
require 'sidekiq_jobs_displayer/actions/base'
require 'sidekiq_jobs_displayer/actions/enqueue_schedule'
require 'sidekiq_jobs_displayer/actions/toggle_schedule'
require 'sidekiq_jobs_displayer/engine' if defined?(Rails::Engine)

# Своя страница фоновых задач Sidekiq: мониторинг, управление запусками, логи и ошибки.
#
# Слои (сверху вниз, каждый знает только о нижних):
#   интерфейс (app/)                 — контроллеры и вьюхи, ходят только в Queries и Actions
#   Queries / Actions                — данные для страниц и команды управления
#   Registry / Schedulers / LogSources — какие задачи есть, их расписания, где их логи
#   Stores                           — всё чтение и запись в Redis
#   Middleware::Recorder             — сбор данных в процессе Sidekiq
#
# Точки входа для приложения: SidekiqJobsDisplayer.configure, include SidekiqJobsDisplayer::Job,
# mount SidekiqJobsDisplayer::Engine.
module SidekiqJobsDisplayer
  class << self
    def config
      @config ||= Configuration.new
    end

    def configure
      yield config
      reset!
    end

    # Сбрасывает настройки и всё, что из них собрано (адаптер расписаний, хранилища).
    def reset_config!
      @config = Configuration.new
      reset!
    end

    def scheduler
      @scheduler ||= Schedulers.resolve(config.scheduler)
    end

    def runs_store
      @runs_store ||= Stores::Runs.new(config)
    end

    def registry
      Registry.new(config: config, scheduler: scheduler, runs_store: runs_store)
    end

    def log_source
      @log_source ||= LogSources.resolve(config.logs.source, config)
    end

    private

    def reset!
      @scheduler = nil
      @runs_store = nil
      @log_source = nil
    end
  end
end
