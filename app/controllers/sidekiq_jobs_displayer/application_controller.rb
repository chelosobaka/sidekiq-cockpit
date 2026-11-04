module SidekiqJobsDisplayer
  # Наследуется от config.parent_controller, чтобы взять из приложения аутентификацию и
  # current_user. Доступ — config.authorize; без него страница отвечает 403.
  # Контроллеры только читают Queries и вызывают Actions.
  class ApplicationController < SidekiqJobsDisplayer.config.parent_controller.constantize
    protect_from_forgery with: :exception

    layout -> { SidekiqJobsDisplayer.config.layout }
    helper SidekiqJobsDisplayer::ApplicationHelper

    before_action { authorize!(:read) }

    rescue_from Actions::Forbidden do
      head :forbidden
    end

    private

    def authorize!(permission)
      raise Actions::Forbidden, permission.to_s unless SidekiqJobsDisplayer.config.authorized?(self, permission)
    end

    def redirect_with(result, fallback:)
      redirect_back_or_to(fallback, (result.ok? ? :notice : :alert) => result.message)
    end
  end
end
