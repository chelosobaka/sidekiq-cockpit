module SidekiqJobsDisplayer
  # Выбор адаптера расписаний по config.scheduler.
  module Schedulers
    REGISTRY = { none: 'None', sidekiq_cron: 'SidekiqCron' }.freeze

    module_function

    def resolve(setting)
      case setting
      when :auto
        SidekiqCron.available? ? SidekiqCron.new : None.new
      when Symbol
        klass = REGISTRY[setting] or raise ArgumentError, "scheduler: неизвестный #{setting.inspect}"
        build(const_get(klass))
      when Class
        build(setting)
      else
        setting
      end
    end

    def build(klass)
      raise SidekiqJobsDisplayer::Error, "scheduler #{klass}: планировщик не подключён" unless klass.available?

      klass.new
    end
  end
end
