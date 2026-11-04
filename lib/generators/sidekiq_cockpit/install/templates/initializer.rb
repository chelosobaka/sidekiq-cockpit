SidekiqCockpit.configure do |c|
  # Доступ. Без этого блока страница отвечает 403. Второй аргумент — действие:
  # :read, :enqueue, :toggle, :retry, :discard, :resolve.
  c.authorize { |controller, _action| controller.respond_to?(:current_user) && controller.current_user&.admin? }
  # c.actor { |controller| controller.current_user&.email } # кто сделал действие
  # c.parent_controller = 'Admin::BaseController'

  # Каталог задач: :paths — файлы *_job.rb в job_paths, :descendants — загруженные классы.
  # c.discovery = :paths
  # c.job_paths = %w[app/sidekiq app/jobs]
  # c.ignore_jobs = %w[ActionMailer::MailDeliveryJob]

  # Расписания: :auto выберет sidekiq-cron, если он подключён; :none; или свой адаптер.
  # c.scheduler = :auto

  # История запусков.
  # c.history.limit = 100
  # c.history.stats_ttl = 48.hours

  # Логи (собираются со следующей версии): :capture — буфер в Redis, :file — общий лог-файл.
  # c.logs.source = :capture
  # c.logs.file = 'log/production.log'
  # c.logs.lines_per_run = 300

  # c.filter_args = %i[password token secret]

  # Отображение.
  # c.time_zone = 'Europe/Moscow'
  # c.title = 'Фоновые задачи'
  # c.back_url = '/admin'
  # c.layout = 'admin' # и тогда Bootstrap подключает лейаут приложения:
  # c.bootstrap_css_url = nil
  # c.bootstrap_js_url = nil
end
