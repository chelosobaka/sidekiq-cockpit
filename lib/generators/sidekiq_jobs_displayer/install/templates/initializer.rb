SidekiqJobsDisplayer.configure do |config|
  # Кто видит страницу. Получает контроллер гема (наследник parent_controller).
  # По умолчанию доступ открыт всем — закройте его здесь или через constraints в routes.rb.
  # config.parent_controller = 'ApplicationController'
  # config.authorize = ->(controller) { controller.current_user&.admin? }

  # Где лежат задачи (файлы *_job.rb), относительно Rails.root.
  # config.job_paths = %w[app/sidekiq app/jobs]

  # Сколько последних запусков хранить по каждой задаче.
  # config.history_limit = 100

  # Middleware истории запусков встаёт в Sidekiq сама; false — если добавляете её вручную.
  # config.install_middleware = true

  # Шапка страницы.
  # config.title = 'Фоновые задачи'
  # config.back_url = '/admin'

  # Свой лейаут с Bootstrap 5 с CDN; можно взять лейаут приложения и подключить Bootstrap там.
  # config.layout = 'admin'
  # config.bootstrap_css_url = nil
  # config.bootstrap_js_url = nil
end
