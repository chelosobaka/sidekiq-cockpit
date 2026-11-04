module SidekiqCockpit
  module Queries
    # Данные страницы «Задачи»: каждая задача, её последний запуск и счётчики за сутки.
    # Разделы: «По расписанию» (есть хотя бы одно расписание) и «По событиям».
    class Overview
      Row = Data.define(:definition, :last_run, :day_stats) do
        delegate :name, :description, :trigger, :schedules, :scheduled?, :group, :runnable?, to: :definition
      end

      Result = Data.define(:scheduled, :events, :capabilities) do
        def empty? = scheduled.empty? && events.empty?
        def rows = scheduled + events
      end

      def initialize(registry: SidekiqCockpit.registry, store: SidekiqCockpit.runs_store,
                     scheduler: SidekiqCockpit.scheduler)
        @registry = registry
        @store = store
        @scheduler = scheduler
      end

      def call(group: nil, failed_only: false)
        definitions = @registry.all
        definitions = definitions.select { |definition| definition.group == group } if group.present?
        names = definitions.map(&:name)
        last_runs = @store.last_runs(names)
        stats = @store.stats_by_class(names)

        rows = definitions.map { |definition| Row.new(definition, last_runs[definition.name], stats[definition.name]) }
        rows = rows.select { |row| row.day_stats.failed.positive? } if failed_only
        scheduled, events = rows.partition(&:scheduled?)
        Result.new(scheduled: scheduled, events: events, capabilities: @scheduler.capabilities)
      end
    end
  end
end
