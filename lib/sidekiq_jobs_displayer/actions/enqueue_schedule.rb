module SidekiqJobsDisplayer
  module Actions
    # Ставит задачу из расписания в очередь сейчас, с аргументами расписания.
    class EnqueueSchedule < Base
      requires :enqueue

      def initialize(schedule_id:, scheduler: SidekiqJobsDisplayer.scheduler, **)
        super(**)
        @schedule_id = schedule_id
        @scheduler = scheduler
      end

      private

      def perform
        @scheduler.enqueue_now(@schedule_id)
        success(I18n.t('sidekiq_jobs_displayer.actions.enqueue_schedule.done'))
      end
    end
  end
end
