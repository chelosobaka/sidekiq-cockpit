module SidekiqCockpit
  # Наследуется от config.parent_controller, чтобы взять из приложения аутентификацию и
  # current_user. Доступ — config.authorize; без него страница отвечает 403.
  # Контроллеры только читают Queries и вызывают Actions.
  class ApplicationController < SidekiqCockpit.config.parent_controller.constantize
    protect_from_forgery with: :exception

    layout -> { SidekiqCockpit.config.layout }
    helper SidekiqCockpit::ApplicationHelper

    before_action { authorize!(:read) }

    rescue_from Actions::Forbidden do
      head :forbidden
    end

    private

    def authorize!(permission)
      raise Actions::Forbidden, permission.to_s unless SidekiqCockpit.config.authorized?(self, permission)
    end

    def redirect_with(result, fallback:)
      redirect_back_or_to(fallback, (result.ok? ? :notice : :alert) => result.message)
    end
  end
end
