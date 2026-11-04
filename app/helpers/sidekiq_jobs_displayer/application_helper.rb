module SidekiqJobsDisplayer
  # Только форматирование: время, длительность, итог запуска.
  module ApplicationHelper
    RESULT_BADGES = { 'ok' => 'text-bg-success', 'failed' => 'text-bg-danger',
                      'interrupted' => 'text-bg-warning' }.freeze

    def sjd_config = SidekiqJobsDisplayer.config

    def sjd_time(time)
      time && l(time.in_time_zone(sjd_config.zone), format: '%d.%m.%Y %H:%M:%S')
    end

    def sjd_duration(seconds)
      return if seconds.nil?
      return t('sidekiq_jobs_displayer.duration.seconds', value: format('%.2f', seconds)) if seconds < 60

      t('sidekiq_jobs_displayer.duration.minutes', min: (seconds / 60).floor, sec: (seconds % 60).round)
    end

    def sjd_can?(permission) = sjd_config.authorized?(controller, permission)

    # Итог запуска: бейдж, номер повтора и текст ошибки.
    def sjd_result(run)
      badge = tag.span(t("sidekiq_jobs_displayer.statuses.#{run.status}", default: run.status),
                       class: "badge #{RESULT_BADGES.fetch(run.status, 'text-bg-secondary')}")
      parts = [badge]
      if run.retry_count
        parts << tag.small(t('sidekiq_jobs_displayer.retry', count: run.retry_count + 1),
                           class: 'text-body-secondary ms-1')
      end
      parts << tag.div(tag.small(run.error), class: 'text-danger text-break') if run.error
      safe_join(parts)
    end

    def sjd_day_runs(stats)
      t('sidekiq_jobs_displayer.day_runs', runs: stats.total)
    end
  end
end
