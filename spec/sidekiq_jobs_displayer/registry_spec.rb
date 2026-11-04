RSpec.describe SidekiqJobsDisplayer::Registry do
  let(:config) { SidekiqJobsDisplayer.config }
  let(:scheduler) { SidekiqJobsDisplayer::Schedulers::None.new }
  let(:store) { SidekiqJobsDisplayer::Stores::Runs.new(config) }
  let(:registry) { SidekiqJobsDisplayer::Registry.new(config: config, scheduler: scheduler, runs_store: store) } # rubocop:disable RSpec/DescribedClass

  it 'находит задачи по путям' do
    expect(registry.all.map(&:name)).to eq(%w[BackupJob ReportJob TelegramSendMessageJob])
  end

  it 'находит задачи по загруженным классам' do
    config.discovery = :descendants

    expect(registry.all.map(&:name)).to include('BackupJob', 'ReportJob', 'TelegramSendMessageJob')
  end

  it 'добавляет задачи из истории запусков и убирает ignore_jobs' do
    store.record(build_run(job_class: 'Vendor::SyncJob'))
    config.ignore_jobs = ['ReportJob']

    expect(registry.all.map(&:name)).to eq(%w[BackupJob TelegramSendMessageJob Vendor::SyncJob])
  end

  it 'добавляет задачи из расписаний адаптера' do
    schedule = SidekiqJobsDisplayer::Schedulers::Schedule.new(
      id: 'x', job_class: 'NightlyJob', cron: '0 3 * * *', time_zone: nil, args: [], queue: nil,
      enabled: true, last_enqueued_at: nil, next_run_at: nil, description: 'Ночная', source: :test
    )
    allow(scheduler).to receive(:schedules).and_return([schedule])

    nightly = registry.find('NightlyJob')
    expect(nightly).to be_scheduled
    expect(nightly).not_to be_loaded
    expect(nightly.description).to eq('Ночная')
  end

  describe SidekiqJobsDisplayer::JobDefinition do
    it 'берёт метаданные из displayer' do
      job = registry.find('BackupJob')

      expect(job).to have_attributes(description: 'Бэкап базы', group: 'Бэкапы', queue: 'backup')
      expect(job).to be_runnable
    end

    it 'без displayer берёт тексты из I18n' do
      job = registry.find('TelegramSendMessageJob')

      expect(job).to have_attributes(description: 'Отправляет сообщение в Telegram', trigger: 'рассылки и уведомления')
      expect(job).not_to be_runnable
    end

    it 'знает очередь ActiveJob' do
      expect(registry.find('ReportJob').queue).to eq('reports')
    end
  end

  describe SidekiqJobsDisplayer::Job do
    it 'не принимает неизвестные ключи и типы аргументов' do
      klass = Class.new { include SidekiqJobsDisplayer::Job }

      expect { klass.displayer(colour: 'red') }.to raise_error(ArgumentError)
      expect { klass.displayer(args: [{ name: :x, type: :date }]) }.to raise_error(ArgumentError)
    end
  end
end
