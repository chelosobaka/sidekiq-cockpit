module SidekiqCockpit
  # Одна задача приложения: имя класса, метаданные из cockpit и её расписания (ноль или
  # несколько). Класса может не быть (задача из расписания или истории, чей код удалён) —
  # тогда известны только имя и расписания.
  class JobDefinition
    attr_reader :name, :schedules

    def initialize(name, schedules: [])
      @name = name
      @schedules = schedules
    end

    def job_class
      return @job_class if defined?(@job_class)

      @job_class = name.safe_constantize
    end

    def loaded?
      !job_class.nil?
    end

    def scheduled?
      schedules.any?
    end

    def options
      job_class.respond_to?(:sidekiq_cockpit_options) ? job_class.sidekiq_cockpit_options : {}
    end

    # Строка из cockpit, иначе I18n, иначе description расписания.
    def description
      text(:description).presence || schedules.filter_map(&:description).first.to_s
    end

    # Что ставит задачу в очередь — для задач по событиям.
    def trigger
      text(:trigger)
    end

    def group
      options[:group]
    end

    def runnable?
      options[:runnable] == true
    end

    def confirm
      options[:confirm]
    end

    def arg_schema
      Array(options[:args])
    end

    def queue
      return unless loaded?

      if defined?(ActiveJob::Base) && job_class <= ActiveJob::Base
        job_class.queue_name.to_s
      elsif job_class.respond_to?(:get_sidekiq_options)
        job_class.get_sidekiq_options['queue']
      end
    end

    def i18n_key
      name.underscore.tr('/', '.')
    end

    private

    def text(key)
      value = options[key]
      return value if value.is_a?(String)

      I18n.t("sidekiq_cockpit.jobs.#{i18n_key}.#{key}", default: '')
    end
  end
end
