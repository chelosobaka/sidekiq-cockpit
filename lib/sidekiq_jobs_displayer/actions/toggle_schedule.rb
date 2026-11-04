module SidekiqJobsDisplayer
  module Actions
    # Включает или отключает расписание.
    class ToggleSchedule < Base
      requires :toggle

      def initialize(schedule_id:, enabled:, scheduler: SidekiqJobsDisplayer.scheduler, **)
        super(**)
        @schedule_id = schedule_id
        @enabled = enabled
        @scheduler = scheduler
      end

      private

      def perform
        @enabled ? @scheduler.enable(@schedule_id) : @scheduler.disable(@schedule_id)
        success(I18n.t("sidekiq_jobs_displayer.actions.toggle_schedule.#{@enabled ? 'enabled' : 'disabled'}"))
      end
    end
  end
end
