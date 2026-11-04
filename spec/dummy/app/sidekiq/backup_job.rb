class BackupJob
  include Sidekiq::Job
  include SidekiqJobsDisplayer::Job

  sidekiq_options queue: 'backup'

  displayer description: 'Бэкап базы', trigger: 'кнопка в админке', group: 'Бэкапы', runnable: true

  def perform; end
end
