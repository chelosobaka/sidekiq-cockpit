module SidekiqCockpit
  # Только форматирование: время, длительность, итог запуска.
  module ApplicationHelper
    RESULT_BADGES = { 'ok' => 'text-bg-success', 'failed' => 'text-bg-danger',
                      'interrupted' => 'text-bg-warning' }.freeze

    def cockpit_config = SidekiqCockpit.config

    def cockpit_time(time)
      time && l(time.in_time_zone(cockpit_config.zone), format: '%d.%m.%Y %H:%M:%S')
    end

    def cockpit_duration(seconds)
      return if seconds.nil?
      return t('sidekiq_cockpit.duration.seconds', value: format('%.2f', seconds)) if seconds < 60

      t('sidekiq_cockpit.duration.minutes', min: (seconds / 60).floor, sec: (seconds % 60).round)
    end

    def cockpit_can?(permission) = cockpit_config.authorized?(controller, permission)

    # Итог запуска: бейдж, номер повтора и текст ошибки.
    def cockpit_result(run)
      badge = tag.span(t("sidekiq_cockpit.statuses.#{run.status}", default: run.status),
                       class: "badge #{RESULT_BADGES.fetch(run.status, 'text-bg-secondary')}")
      parts = [badge]
      if run.retry_count
        parts << tag.small(t('sidekiq_cockpit.retry', count: run.retry_count + 1),
                           class: 'text-body-secondary ms-1')
      end
      parts << tag.div(tag.small(run.error), class: 'text-danger text-break') if run.error
      safe_join(parts)
    end

    def cockpit_day_runs(stats)
      t('sidekiq_cockpit.day_runs', runs: stats.total)
    end
  end
end
