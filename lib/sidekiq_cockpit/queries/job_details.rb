module SidekiqCockpit
  module Queries
    # Данные страницы задачи: описание, расписания, последние запуски, почасовые счётчики.
    class JobDetails
      Result = Data.define(:definition, :runs, :day_stats, :hourly, :capabilities) do
        delegate :name, :description, :trigger, :schedules, :scheduled?, :group, :runnable?, to: :definition
      end

      def initialize(registry: SidekiqCockpit.registry, store: SidekiqCockpit.runs_store,
                     scheduler: SidekiqCockpit.scheduler)
        @registry = registry
        @store = store
        @scheduler = scheduler
      end

      # nil, если такой задачи нет.
      def call(name)
        definition = @registry.find(name) or return
        hourly = @store.hourly_by_class([name]).fetch(name)
        day_stats = hourly.sum(Stores::Runs::Stats.empty, &:last)
        Result.new(definition: definition, runs: @store.runs(name), day_stats: day_stats, hourly: hourly,
                   capabilities: @scheduler.capabilities)
      end
    end
  end
end
