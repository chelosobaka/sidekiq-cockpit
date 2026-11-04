class BackupJob
  include Sidekiq::Job
  include SidekiqCockpit::Job

  sidekiq_options queue: 'backup'

  cockpit description: 'Бэкап базы', trigger: 'кнопка в админке', group: 'Бэкапы', runnable: true

  def perform; end
end
