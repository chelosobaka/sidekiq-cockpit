module SidekiqCockpit
  module Schedulers
    class NotSupported < SidekiqCockpit::Error; end

    # Одно расписание задачи, в виде, не зависящем от планировщика.
    Schedule = Data.define(:id, :job_class, :cron, :time_zone, :args, :queue, :enabled,
                           :last_enqueued_at, :next_run_at, :description, :source) do
      def enabled? = enabled
    end

    # Интерфейс адаптера расписаний. Свой адаптер наследуется от Base, возвращает Schedule
    # из #schedules и объявляет в #capabilities то, что умеет: интерфейс показывает только
    # эти кнопки.
    #
    #   :toggle       — enable / disable
    #   :enqueue_now  — поставить в очередь сейчас
    class Base
      CAPABILITIES = %i[toggle enqueue_now].freeze

      def self.available? = true

      def name = self.class.name.demodulize.underscore

      def schedules = []

      def find(id) = schedules.find { |schedule| schedule.id == id }

      def capabilities = []

      def supports?(capability) = capabilities.include?(capability)

      def enable(_id) = raise(NotSupported, "#{name}: enable")

      def disable(_id) = raise(NotSupported, "#{name}: disable")

      def enqueue_now(_id) = raise(NotSupported, "#{name}: enqueue_now")
    end
  end
end
