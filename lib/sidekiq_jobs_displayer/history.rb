module SidekiqJobsDisplayer
  # История запусков задач в Redis. Sidekiq сам выполненные задачи не хранит, поэтому
  # Middleware после каждого запуска пишет сюда: когда начался, сколько шёл, очередь,
  # аргументы (коротко) и итог. По каждой задаче — свой список, чтобы частые задачи не
  # вытесняли редкие. Ошибка записи задачу не ломает — только строка в лог.
  module History
    ARGS_LIMIT = 200
    ERROR_LIMIT = 500
    STATUSES = %w[ok failed interrupted].freeze

    Run = Struct.new(:started_at, :duration, :queue, :status, :error, :args, :retry_count, keyword_init: true) do
      def ok?
        status == 'ok'
      end

      def failed?
        !ok?
      end
    end

    module_function

    def key(klass)
      "#{SidekiqJobsDisplayer.config.redis_key_prefix}#{klass}"
    end

    def limit
      SidekiqJobsDisplayer.config.history_limit
    end

    def record(payload, queue, started_at:, duration:, status:, error: nil)
      klass = payload['wrapped'] || payload['class']
      Sidekiq.redis do |conn|
        conn.pipelined do |pipeline|
          pipeline.lpush(key(klass), Sidekiq.dump_json(entry(payload, queue, started_at, duration, status, error)))
          pipeline.ltrim(key(klass), 0, limit - 1)
        end
      end
    rescue StandardError => e
      Sidekiq.logger.warn("SidekiqJobsDisplayer: запуск #{klass} не записан: #{e.class}: #{e.message}")
    end

    def entry(payload, queue, started_at, duration, status, error)
      { 'at' => started_at.to_f, 'ms' => (duration * 1000).round, 'queue' => queue, 'status' => status,
        'error' => error && "#{error.class}: #{error.message}".truncate(ERROR_LIMIT),
        'args' => Sidekiq.dump_json(payload['args'] || []).truncate(ARGS_LIMIT),
        'retry' => payload['retry_count'] }.compact
    end

    # Последние запуски задачи, новые сверху.
    def runs(klass, count: limit)
      Sidekiq.redis { |conn| conn.lrange(key(klass), 0, count - 1) }.map { |raw| parse(raw) }
    end

    # Последние запуски нескольких задач одним запросом к Redis: { 'AJob' => [Run, ...] }.
    def runs_by_class(klasses)
      return {} if klasses.empty?

      lists = Sidekiq.redis do |conn|
        conn.pipelined { |pipeline| klasses.each { |klass| pipeline.lrange(key(klass), 0, limit - 1) } }
      end
      klasses.zip(lists).to_h { |klass, list| [klass, Array(list).map { |raw| parse(raw) }] }
    end

    def clear(klass)
      Sidekiq.redis { |conn| conn.del(key(klass)) }
    end

    def parse(raw)
      data = Sidekiq.load_json(raw)
      Run.new(started_at: Time.zone.at(data['at']), duration: data['ms'].to_i / 1000.0, queue: data['queue'],
              status: data['status'], error: data['error'], args: data['args'], retry_count: data['retry'])
    end
  end
end
