module SidekiqCockpit
  # Только форматирование, без разметки и стилей: разметка целиком во вьюхах.
  module ApplicationHelper
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
  end
end
