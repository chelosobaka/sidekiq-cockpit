module SidekiqJobsDisplayer
  # Страница «Задачи»: все задачи — по расписанию и по событиям; по задаче — её последние
  # запуски и управление расписанием (sidekiq-cron).
  class JobsController < ApplicationController
    before_action :set_row, only: %i[show enqueue enable disable]
    before_action :require_cron_job, only: %i[enqueue enable disable]

    def index
      @rows = Overview.rows
    end

    def show; end

    def enqueue
      @row.cron_job.enqueue!
      redirect_back_to_job t('.done')
    end

    def enable
      @row.cron_job.enable!
      redirect_back_to_job t('.done')
    end

    def disable
      @row.cron_job.disable!
      redirect_back_to_job t('.done')
    end

    private

    def set_row
      @row = Overview.find(params[:name])
      raise ActionController::RoutingError, "Unknown job #{params[:name]}" unless @row
    end

    def require_cron_job
      redirect_back_to_job(t('sidekiq_jobs_displayer.jobs.not_scheduled'), :alert) unless @row.scheduled?
    end

    def redirect_back_to_job(message, type = :notice)
      redirect_back fallback_location: job_path(@row.name), type => message
    end
  end
end
