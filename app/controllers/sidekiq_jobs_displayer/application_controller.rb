module SidekiqJobsDisplayer
  # Наследуется от config.parent_controller, чтобы взять из приложения аутентификацию и
  # current_user; доступ — через config.authorize.
  class ApplicationController < SidekiqJobsDisplayer.config.parent_controller.constantize
    protect_from_forgery with: :exception

    layout -> { SidekiqJobsDisplayer.config.layout }

    before_action :authorize_sidekiq_jobs_displayer!

    private

    def authorize_sidekiq_jobs_displayer!
      head :forbidden unless SidekiqJobsDisplayer.config.authorize.call(self)
    end
  end
end
