module SidekiqJobsDisplayer
  # Источники логов запусков. Страницы читают логи только через этот интерфейс, а где они
  # лежат, решает config.logs.source. Сами источники — шаг 2 плана; сейчас заложен интерфейс
  # и выбор по настройке.
  module LogSources
    Line = Data.define(:time, :level, :message, :jid)

    # Интерфейс источника.
    class Base
      attr_reader :config

      def initialize(config)
        @config = config
      end

      # Строки одного запуска (Stores::Runs::Run), по времени.
      def lines_for(_run) = raise(NotImplementedError, "#{self.class}#lines_for")

      # Поиск по логам задач с момента since.
      def search(_query, since:) = raise(NotImplementedError, "#{self.class}#search")
    end

    # Логи выключены (config.logs.enabled = false).
    class Disabled < Base
      def lines_for(_run) = []

      def search(_query, since:) = [] # rubocop:disable Lint/UnusedMethodArgument
    end

    # Буфер строк в процессе Sidekiq, затем Redis. Шаг 2.
    class Capture < Base
    end

    # Общий лог-файл приложения, строки ищутся по jid и времени запуска. Шаг 2.
    class File < Base
    end

    SOURCES = { capture: Capture, file: File }.freeze

    module_function

    def resolve(setting, config)
      return Disabled.new(config) unless config.logs.enabled

      klass = setting.is_a?(Class) ? setting : SOURCES[setting]
      raise ArgumentError, "logs.source: неизвестный #{setting.inspect}" unless klass && klass <= Base

      klass.new(config)
    end
  end
end
