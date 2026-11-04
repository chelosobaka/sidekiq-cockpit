module SidekiqJobsDisplayer
  module Schedulers
    # Адаптер sidekiq-cron (>= 2.0). Единственное место модуля, где есть Sidekiq::Cron:
    # гем не указан в gemspec, адаптер выбирается, только если приложение его подключило.
    #
    # id расписания — "<namespace>/<name>", потому что в sidekiq-cron 2 имена уникальны только
    # внутри namespace.
    class SidekiqCron < Base
      def self.available?
        defined?(::Sidekiq::Cron::Job) ? true : false
      end

      def capabilities = %i[toggle enqueue_now]

      def schedules
        ::Sidekiq::Cron::Job.all('*').map { |job| to_schedule(job) }.sort_by(&:id)
      end

      def find(id)
        job = find_job(id)
        job && to_schedule(job)
      end

      def enable(id) = fetch_job(id).enable!

      def disable(id) = fetch_job(id).disable!

      def enqueue_now(id) = fetch_job(id).enqueue!

      private

      def to_schedule(job)
        enabled = job.status == 'enabled'
        Schedule.new(
          id: "#{job.namespace}/#{job.name}", job_class: job.klass.to_s, cron: job.cron,
          time_zone: parse_cron(job.cron)&.timezone&.name, args: Array(job.args), queue: queue(job),
          enabled: enabled, last_enqueued_at: job.last_enqueue_time,
          next_run_at: enabled ? next_time(job.cron) : nil,
          description: job.description.presence, source: :sidekiq_cron
        )
      end

      def queue(job)
        message = job.message.is_a?(String) ? Sidekiq.load_json(job.message) : job.message
        message.is_a?(Hash) ? message['queue'] : nil
      rescue JSON::ParserError
        nil
      end

      def next_time(cron)
        time = parse_cron(cron)&.next_time
        time && Time.at(time.to_f).utc
      end

      def parse_cron(cron)
        Fugit.parse_cronish(cron)
      rescue ArgumentError
        nil
      end

      def find_job(id)
        namespace, name = id.to_s.split('/', 2)
        return if name.blank?

        ::Sidekiq::Cron::Job.find(name, namespace)
      end

      def fetch_job(id)
        find_job(id) || raise(ArgumentError, "Нет расписания #{id}")
      end
    end
  end
end
