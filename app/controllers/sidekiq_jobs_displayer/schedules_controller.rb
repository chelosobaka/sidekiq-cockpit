module SidekiqJobsDisplayer
  # Управление расписаниями. Кнопки показываются, только если адаптер это умеет
  # (Schedulers::Base#capabilities).
  class SchedulesController < ApplicationController
    def enable
      redirect_with Actions::ToggleSchedule.call(schedule_id: params[:id], enabled: true, controller: self),
                    fallback: root_path
    end

    def disable
      redirect_with Actions::ToggleSchedule.call(schedule_id: params[:id], enabled: false, controller: self),
                    fallback: root_path
    end

    def enqueue
      redirect_with Actions::EnqueueSchedule.call(schedule_id: params[:id], controller: self), fallback: root_path
    end
  end
end
