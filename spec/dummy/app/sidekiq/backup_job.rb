class BackupJob
  include Sidekiq::Job

  def perform; end
end
