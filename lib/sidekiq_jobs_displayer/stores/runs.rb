module SidekiqJobsDisplayer
  module Stores
    # Запуски задач и часовые счётчики.
    #
    #   sjd:runs:<Class>          list  последние запуски, новые сверху (history.limit записей)
    #   sjd:stats:<Class>:<час>   hash  ok / failed / interrupted / ms за час (history.stats_ttl)
    #   sjd:jobs                  set   все классы, которые хоть раз запускались
    #
    # Счётчики дают точное число запусков за сутки даже у задач, которые запускаются чаще,
    # чем помещается в список.
    class Runs < RedisStore
      STATUSES = %w[ok failed interrupted].freeze

      Run = Data.define(:jid, :job_class, :queue, :started_at, :duration, :status, :error_class,
                        :error_message, :args, :retry_count) do
        def ok? = status == 'ok'
        def failed? = status == 'failed'
        def interrupted? = status == 'interrupted'

        def error
          error_class && [error_class, error_message].compact.join(': ')
        end
      end

      Stats = Data.define(:ok, :failed, :interrupted, :total_ms) do
        def self.empty = new(ok: 0, failed: 0, interrupted: 0, total_ms: 0)

        def total = ok + failed + interrupted

        def average_duration = total.zero? ? nil : total_ms / total / 1000.0

        def +(other)
          Stats.new(ok: ok + other.ok, failed: failed + other.failed,
                    interrupted: interrupted + other.interrupted, total_ms: total_ms + other.total_ms)
        end
      end

      def record(run)
        raise ArgumentError, "status: #{run.status}" unless STATUSES.include?(run.status)

        stats_key = key('stats', run.job_class, hour_bucket(run.started_at))
        redis do |conn|
          conn.pipelined do |pipe|
            pipe.lpush(key('runs', run.job_class), dump(serialize(run)))
            pipe.ltrim(key('runs', run.job_class), 0, config.history.limit - 1)
            pipe.hincrby(stats_key, run.status, 1)
            pipe.hincrby(stats_key, 'ms', (run.duration * 1000).round)
            pipe.expire(stats_key, config.history.stats_ttl.to_i)
            pipe.sadd(key('jobs'), [run.job_class])
          end
        end
      end

      def runs(job_class, limit: config.history.limit)
        redis { |conn| conn.lrange(key('runs', job_class), 0, limit - 1) }.map { |raw| deserialize(raw) }
      end

      def last_runs(job_classes)
        return {} if job_classes.empty?

        raws = redis do |conn|
          conn.pipelined do |pipe|
            job_classes.each do |klass|
              pipe.lindex(key('runs', klass), 0)
            end
          end
        end
        job_classes.zip(raws).to_h { |klass, raw| [klass, raw && deserialize(raw)] }
      end

      # Счётчики за последние hours часов (включая текущий).
      def stats(job_class, hours: 24, now: Time.current)
        stats_by_class([job_class], hours: hours, now: now).fetch(job_class)
      end

      def stats_by_class(job_classes, hours: 24, now: Time.current)
        hourly_by_class(job_classes, hours: hours, now: now).transform_values do |series|
          series.sum(Stats.empty, &:last)
        end
      end

      # Почасовые счётчики: { 'AJob' => [[Time начала часа, Stats], ...] } от старых к новым.
      def hourly_by_class(job_classes, hours: 24, now: Time.current)
        return {} if job_classes.empty?

        buckets = (0...hours).map { |ago| hour_bucket(now - ago.hours) }.reverse
        hashes = redis do |conn|
          conn.pipelined do |pipe|
            job_classes.each { |klass| buckets.each { |bucket| pipe.hgetall(key('stats', klass, bucket)) } }
          end
        end
        job_classes.each_with_index.to_h do |klass, index|
          slice = hashes[index * buckets.size, buckets.size]
          [klass, buckets.zip(slice).map { |bucket, hash| [config.zone.at(bucket * 3600), to_stats(hash)] }]
        end
      end

      def known_job_classes
        redis { |conn| conn.smembers(key('jobs')) }.sort
      end

      def clear(job_class)
        redis do |conn|
          stats_keys = conn.scan(match: key('stats', job_class, '*')).to_a
          conn.del(key('runs', job_class), *stats_keys)
          conn.srem(key('jobs'), [job_class])
        end
      end

      private

      def hour_bucket(time) = time.to_i / 3600

      def serialize(run)
        { 'jid' => run.jid, 'class' => run.job_class, 'queue' => run.queue, 'at' => run.started_at.to_f,
          'ms' => (run.duration * 1000).round, 'status' => run.status, 'ec' => run.error_class,
          'em' => run.error_message, 'args' => run.args, 'retry' => run.retry_count }.compact
      end

      def deserialize(raw)
        data = load(raw)
        Run.new(jid: data['jid'], job_class: data['class'], queue: data['queue'],
                started_at: config.zone.at(data['at']), duration: data['ms'].to_i / 1000.0,
                status: data['status'], error_class: data['ec'], error_message: data['em'],
                args: data['args'], retry_count: data['retry'])
      end

      def to_stats(hash)
        hash ||= {}
        Stats.new(ok: hash['ok'].to_i, failed: hash['failed'].to_i, interrupted: hash['interrupted'].to_i,
                  total_ms: hash['ms'].to_i)
      end
    end
  end
end
