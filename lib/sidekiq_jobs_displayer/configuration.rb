module SidekiqJobsDisplayer
  # Настройки гема. Все значения по умолчанию рассчитаны на типичное приложение Rails 7:
  # задачи в app/sidekiq и app/jobs, расписание — sidekiq-cron.
  class Configuration
    # Откуда брать список задач приложения: каталоги относительно Rails.root, файлы *_job.rb.
    attr_accessor :job_paths

    # Сколько последних запусков хранить по каждой задаче (список в Redis, LPUSH + LTRIM).
    attr_accessor :history_limit

    # Префикс ключей истории в Redis.
    attr_accessor :redis_key_prefix

    # Ставить ли middleware истории в цепочку Sidekiq автоматически.
    attr_accessor :install_middleware

    # Контроллер приложения, от которого наследуется контроллер гема (аутентификация,
    # current_user и прочее берутся оттуда).
    attr_accessor :parent_controller

    # Проверка доступа: lambda, получает контроллер; false — 403. По умолчанию доступ открыт,
    # поэтому в проде страницу закрывают либо этим, либо constraints в routes.rb.
    attr_accessor :authorize

    # Ссылка «В приложение» в шапке; nil — кнопки нет.
    attr_accessor :back_url

    # Название в шапке страницы.
    attr_accessor :title

    # Лейаут: по умолчанию свой (Bootstrap 5 с CDN), можно указать лейаут приложения.
    attr_accessor :layout

    # Откуда грузить Bootstrap в своём лейауте; nil — не грузить (приложение подключает само).
    attr_accessor :bootstrap_css_url, :bootstrap_js_url

    def initialize
      @job_paths = %w[app/sidekiq app/jobs]
      @history_limit = 100
      @redis_key_prefix = 'sidekiq_jobs_displayer:history:'
      @install_middleware = true
      @parent_controller = 'ActionController::Base'
      @authorize = ->(_controller) { true }
      @back_url = nil
      @title = 'Фоновые задачи'
      @layout = 'sidekiq_jobs_displayer/application'
      @bootstrap_css_url = 'https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/css/bootstrap.min.css'
      @bootstrap_js_url = 'https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/js/bootstrap.bundle.min.js'
    end
  end
end
