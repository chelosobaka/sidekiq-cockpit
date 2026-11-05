module SidekiqCockpit
  # Все настройки модуля и их значения по умолчанию. Задаются одним блоком:
  #
  #   SidekiqCockpit.configure do |c|
  #     c.authorize { |controller, action| controller.current_user&.admin? }
  #     c.history.limit = 200
  #   end
  #
  # Обязательна только проверка доступа: без c.authorize страница отвечает 403.
  class Configuration
    DISCOVERY_MODES = %i[paths descendants].freeze
    PERMISSIONS = %i[read enqueue toggle retry discard resolve].freeze

    # История запусков: сколько последних запусков хранить по задаче и сколько живут
    # часовые счётчики.
    class History
      attr_accessor :limit, :stats_ttl

      def initialize
        @limit = 100
        @stats_ttl = 48.hours
      end
    end

    # Логи запусков. Сбор и показ — шаг 2 плана; здесь только настройки и выбор источника.
    class Logs
      attr_accessor :enabled, :source, :file, :parser, :level, :lines_per_run, :ttl, :keep_failed_for

      def initialize
        @enabled = true
        @source = :capture         # :capture, :file или свой класс-наследник LogSources::Base
        @file = 'log/production.log'
        @parser = :sidekiq_default # формат строк для :file: :sidekiq_default, :json или lambda
        @level = :info
        @lines_per_run = 300
        @ttl = 3.days
        @keep_failed_for = 14.days
      end
    end

    # Группы ошибок (шаг 2 плана).
    class Errors
      attr_accessor :ttl, :app_backtrace_filter

      def initialize
        @ttl = 30.days
        @app_backtrace_filter = ->(line) { defined?(Rails.root) && Rails.root && line.include?(Rails.root.to_s) }
      end
    end

    attr_reader :history, :logs, :errors, :discovery, :new_error_hooks

    # Контроллер приложения, от которого наследуются контроллеры модуля.
    attr_accessor :parent_controller

    # Каталоги задач для discovery = :paths (относительно Rails.root, файлы *_job.rb).
    attr_accessor :job_paths

    # Классы, которых не должно быть в списке.
    attr_accessor :ignore_jobs

    # Адаптер расписаний: :auto, :sidekiq_cron, :none, класс или готовый объект.
    attr_accessor :scheduler

    # Ключи, которые маскируются в аргументах (и в логах на шаге 2).
    attr_accessor :filter_args

    # Отображение.
    attr_accessor :time_zone, :title, :layout, :back_url

    # Префикс всех ключей модуля в Redis.
    attr_accessor :redis_key_prefix

    def initialize
      @history = History.new
      @logs = Logs.new
      @errors = Errors.new
      @parent_controller = 'ActionController::Base'
      @discovery = :paths
      @job_paths = %w[app/sidekiq app/jobs]
      @ignore_jobs = []
      @scheduler = :auto
      @filter_args = %i[password token secret]
      @time_zone = nil # nil — Time.zone приложения
      @title = 'Фоновые задачи'
      @layout = 'sidekiq_cockpit/application'
      @back_url = nil
      @redis_key_prefix = 'cockpit'
      @authorize = nil
      @actor = nil
      @new_error_hooks = []
    end

    def discovery=(mode)
      unless DISCOVERY_MODES.include?(mode)
        raise ArgumentError,
              "discovery: #{mode.inspect}, ожидается #{DISCOVERY_MODES.join(' или ')}"
      end

      @discovery = mode
    end

    # Проверка доступа. Блок получает контроллер и действие (:read, :enqueue, :toggle, …);
    # можно принимать только контроллер.
    def authorize(&block)
      @authorize = block if block
      @authorize
    end

    # Кто сделал действие — для аудита и пометки ручных запусков.
    def actor(&block)
      @actor = block if block
      @actor
    end

    # Хук на новую группу ошибок (вызывается на шаге 2).
    def on_new_error(&block)
      @new_error_hooks << block if block
      @new_error_hooks
    end

    def authorized?(controller, permission)
      return false unless @authorize
      raise ArgumentError, "Неизвестное право #{permission.inspect}" unless PERMISSIONS.include?(permission)

      args = @authorize.arity == 1 ? [controller] : [controller, permission]
      @authorize.call(*args) ? true : false
    end

    def actor_for(controller)
      @actor&.call(controller)
    end

    def zone
      time_zone ? ActiveSupport::TimeZone[time_zone] : Time.zone || ActiveSupport::TimeZone['UTC']
    end
  end
end
