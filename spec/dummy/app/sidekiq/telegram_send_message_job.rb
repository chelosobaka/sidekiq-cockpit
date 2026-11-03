class TelegramSendMessageJob
  include Sidekiq::Job

  def perform(_chat_id, _text); end
end
