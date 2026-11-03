require_relative 'lib/sidekiq_jobs_displayer/version'

Gem::Specification.new do |spec|
  spec.name        = 'sidekiq_jobs_displayer'
  spec.version     = SidekiqJobsDisplayer::VERSION
  spec.authors     = ['chelosobaka']
  spec.summary     = 'Страница управления фоновыми задачами и расписаниями Sidekiq для Rails 7'
  spec.description = 'Rails-engine: все задачи приложения — по расписанию (sidekiq-cron) и по событиям — ' \
                     'с описанием, следующим и последним запуском, итогом и счётчиками за сутки. Bootstrap 5.'
  spec.license     = 'MIT'
  spec.homepage    = 'https://github.com/chelosobaka/sidekiq_jobs_displayer'
  spec.required_ruby_version = '>= 3.1'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir['{app,config,lib}/**/*', 'LICENSE', 'README.md', 'CHANGELOG.md']

  spec.add_dependency 'rails', '>= 7.0', '< 8'
  spec.add_dependency 'sidekiq', '>= 7.0', '< 8'
  spec.add_dependency 'sidekiq-cron', '>= 2.0', '< 3'
end
