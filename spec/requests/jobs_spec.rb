RSpec.describe 'Страницы задач', type: :request do
  it 'без authorize отвечает 403' do
    SidekiqJobsDisplayer.reset_config!

    get '/admin/sidekiq'
    expect(response).to have_http_status(:forbidden)
  end

  it 'показывает задачи по событиям и описания' do
    get '/admin/sidekiq'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('По событиям', 'BackupJob', 'ReportJob', 'Бэкап базы',
                                     'Отправляет сообщение в Telegram', 'запусков ещё не было')
  end

  it 'показывает страницу задачи с запусками' do
    SidekiqJobsDisplayer.runs_store.record(build_run(status: 'failed', error_class: 'RuntimeError',
                                                     error_message: 'SSH'))

    get '/admin/sidekiq/jobs/BackupJob'

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('ошибка', 'RuntimeError: SSH', 'с ошибкой: 1')
  end

  it 'на неизвестную задачу — 404' do
    get '/admin/sidekiq/jobs/NopeJob'
    expect(response).to have_http_status(:not_found)
  end

  context 'с sidekiq-cron', :cron do
    before { create_cron }

    it 'показывает раздел по расписанию с кнопками' do
      get '/admin/sidekiq'

      expect(response.body).to include('По расписанию', '0 0,12 * * * Europe/Moscow', 'Отключить', 'Запустить сейчас')
    end

    it 'отключает расписание' do
      post '/admin/sidekiq/schedules/default/backup/disable'

      expect(Sidekiq::Cron::Job.find('backup').status).to eq('disabled')
      expect(flash[:notice]).to eq('Расписание отключено')
    end

    it 'прячет кнопки без права toggle и не даёт его обойти' do
      SidekiqJobsDisplayer.config.authorize { |_controller, action| action == :read }

      get '/admin/sidekiq'
      expect(response.body).not_to include('Отключить')

      post '/admin/sidekiq/schedules/default/backup/disable'
      expect(response).to have_http_status(:forbidden)
      expect(Sidekiq::Cron::Job.find('backup').status).to eq('enabled')
    end
  end

  context 'без sidekiq-cron', cron: false do
    it 'не показывает раздел по расписанию' do
      get '/admin/sidekiq'

      expect(response.body).not_to include('По расписанию')
    end
  end
end
