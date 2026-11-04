module SidekiqJobsDisplayer
  module Middleware
    # Серверная middleware Sidekiq: записывает итог каждого запуска в Stores::Runs.
    # Исключение задачи пробрасывается дальше — повторы и DeadSet работают как обычно.
    # Ошибка записи задачу не ломает — только строка в лог.
    #
    # На шаге 2 здесь же открывается буфер логов запуска (LogSources) и пишется группа ошибки.
    class Recorder
      include Sidekiq::ServerMiddleware

      ERROR_MESSAGE_LIMIT = 1000
      ARGS_LIMIT = 500

      def initialize(store: nil, config: nil)
        @store = store
        @config = config
      end

      def call(_job, payload, queue)
        started_at = Time.current
        clock = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        yield
        record(payload, queue, started_at, clock, 'ok')
      rescue Sidekiq::Shutdown
        record(payload, queue, started_at, clock, 'interrupted')
        raise
      rescue Exception => e # rubocop:disable Lint/RescueException -- пишем итог и пробрасываем дальше
        record(payload, queue, started_at, clock, 'failed', e)
        raise
      end

      private

      def config = @config || SidekiqJobsDisplayer.config

      def store = @store || SidekiqJobsDisplayer.runs_store

      def record(payload, queue, started_at, clock, status, error = nil)
        run = Stores::Runs::Run.new(
          jid: payload['jid'], job_class: job_class(payload), queue: queue, started_at: started_at,
          duration: Process.clock_gettime(Process::CLOCK_MONOTONIC) - clock, status: status,
          error_class: error&.class&.name, error_message: error&.message.to_s.truncate(ERROR_MESSAGE_LIMIT).presence,
          args: display_args(payload), retry_count: payload['retry_count']
        )
        store.record(run)
      rescue StandardError => e
        Sidekiq.logger.warn("SidekiqJobsDisplayer: запуск #{job_class(payload)} не записан: #{e.class}: #{e.message}")
      end

      def job_class(payload)
        payload['wrapped'] || payload['class']
      end

      # Аргументы для показа: у ActiveJob — arguments из обёртки; секреты маскируются.
      def display_args(payload)
        args = payload['args'] || []
        args = Array(args.first['arguments']) if payload['wrapped'] && args.first.is_a?(Hash)
        Sidekiq.dump_json(filter(args)).truncate(ARGS_LIMIT)
      end

      def filter(args)
        filter = ActiveSupport::ParameterFilter.new(config.filter_args)
        args.map { |arg| arg.is_a?(Hash) ? filter.filter(arg) : arg }
      end
    end
  end
end
