module SidekiqJobsDisplayer
  # Строки страницы «Задачи»: каждая задача приложения, её расписание (sidekiq-cron) и
  # последние запуски. Сначала — по расписанию, потом — по событиям.
  class Overview
    Row = Struct.new(:name, :cron_job, :runs, keyword_init: true) do
      def scheduled?
        !cron_job.nil?
      end

      def enabled?
        scheduled? && cron_job.status == 'enabled'
      end

      def last_run
        runs.first
      end

      # Следующий запуск по расписанию; у отключённой задачи — нет.
      def next_run_at
        return unless enabled?

        Time.zone.at(Fugit::Cron.parse(cron_job.cron).next_time.to_f)
      end

      # Описание: из расписания (description в schedule.yml), иначе из I18n.
      def description
        cron_job&.description.presence ||
          I18n.t("sidekiq_jobs_displayer.jobs.#{name.underscore}.description", default: '')
      end

      # Человеческое «когда запускается»: для расписания — подпись из I18n, для задач по
      # событиям — что их ставит в очередь.
      def trigger
        key = scheduled? ? 'schedule' : 'trigger'
        I18n.t("sidekiq_jobs_displayer.jobs.#{name.underscore}.#{key}", default: '')
      end

      def runs_since(time)
        runs.select { |run| run.started_at >= time }
      end

      # Хранится history_limit последних запусков: если все они за сутки, запусков было не меньше.
      def day_runs_label
        count = runs_since(1.day.ago).size
        count >= SidekiqJobsDisplayer.config.history_limit ? "#{count}+" : count.to_s
      end

      def day_failures
        runs_since(1.day.ago).count(&:failed?)
      end
    end

    class << self
      def rows
        names = job_names
        crons = cron_jobs.index_by(&:klass)
        runs = History.runs_by_class(names)
        names.map { |name| Row.new(name: name, cron_job: crons[name], runs: runs[name]) }
             .partition(&:scheduled?).flatten
      end

      def find(name)
        return unless job_names.include?(name)

        Row.new(name: name, cron_job: cron_jobs.find { |job| job.klass == name }, runs: History.runs(name))
      end

      # Задачи приложения: файлы *_job.rb в config.job_paths плюс классы из расписания, даже
      # если они лежат в другом месте.
      def job_names
        from_files = SidekiqJobsDisplayer.config.job_paths.flat_map do |dir|
          Rails.root.glob("#{dir}/**/*_job.rb").map do |path|
            path.relative_path_from(Rails.root.join(dir)).to_s.delete_suffix('.rb').camelize
          end
        end
        (from_files + cron_jobs.map(&:klass)).uniq.sort
      end

      def cron_jobs
        Sidekiq::Cron::Job.all
      end
    end
  end
end
