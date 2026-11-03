RSpec.describe 'Jobs page', type: :request do
  before do
    Sidekiq::Cron::Job.create(name: 'backup', cron: '0 0,12 * * * Europe/Moscow', class: 'BackupJob',
                              description: 'Бэкап базы')
  end

  it 'показывает задачи по расписанию и по событиям' do
    get '/admin/jobs'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('По расписанию', 'По событиям', 'BackupJob', 'TelegramSendMessageJob',
                                     'Бэкап базы', 'запусков ещё не было')
  end

  it 'показывает историю задачи' do
    SidekiqJobsDisplayer::Middleware.new.call(nil, { 'class' => 'BackupJob', 'args' => [] }, 'backup') { nil }

    get '/admin/jobs/BackupJob'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('успешно', 'Запустить сейчас')
  end

  it 'отключает расписание' do
    post '/admin/jobs/BackupJob/disable'

    expect(Sidekiq::Cron::Job.find('backup').status).to eq('disabled')
  end

  it 'закрывает доступ через config.authorize' do
    SidekiqJobsDisplayer.config.authorize = ->(_controller) { false }

    get '/admin/jobs'

    expect(response).to have_http_status(:forbidden)
  end
end
