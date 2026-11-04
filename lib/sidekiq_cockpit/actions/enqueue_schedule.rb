module SidekiqCockpit
  module Actions
    # Ставит задачу из расписания в очередь сейчас, с аргументами расписания.
    class EnqueueSchedule < Base
      requires :enqueue

      def initialize(schedule_id:, scheduler: SidekiqCockpit.scheduler, **)
        super(**)
        @schedule_id = schedule_id
        @scheduler = scheduler
      end

      private

      def perform
        @scheduler.enqueue_now(@schedule_id)
        success(I18n.t('sidekiq_cockpit.actions.enqueue_schedule.done'))
      end
    end
  end
end
