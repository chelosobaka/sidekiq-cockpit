require_relative 'lib/sidekiq_jobs_displayer/version'

Gem::Specification.new do |spec|
  spec.name        = 'sidekiq_jobs_displayer'
  spec.version     = SidekiqJobsDisplayer::VERSION
  spec.authors     = ['chelosobaka']
  spec.summary     = 'Страница управления фоновыми задачами Sidekiq для Rails 7.1+'
  spec.description = 'Rails-engine: мониторинг задач по расписанию и по событиям, управление запусками, ' \
                     'логи и ошибки. Планировщики (sidekiq-cron и др.) подключаются через адаптеры. Bootstrap 5.'
  spec.license     = 'MIT'
  spec.homepage    = 'https://github.com/chelosobaka/sidekiq_jobs_displayer'
  spec.required_ruby_version = '>= 3.2'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['{app,config,lib}/**/*', 'LICENSE', 'README.md', 'CHANGELOG.md']

  # sidekiq-cron здесь нет намеренно: адаптер Schedulers::SidekiqCron включается, если
  # приложение подключило его само.
  spec.add_dependency 'rails', '>= 7.1', '< 8'
  spec.add_dependency 'sidekiq', '>= 7.0', '< 8'
end
