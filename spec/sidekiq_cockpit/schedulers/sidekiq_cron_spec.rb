RSpec.describe 'SidekiqCockpit::Schedulers::SidekiqCron', :cron do
  let(:scheduler) { SidekiqCockpit::Schedulers::SidekiqCron.new }

  before { create_cron(description: 'Бэкап', queue: 'backup') }

  it 'отдаёт расписания в общем виде' do
    schedule = scheduler.schedules.sole

    expect(schedule).to have_attributes(id: 'default/backup', job_class: 'BackupJob', enabled: true,
                                        queue: 'backup', description: 'Бэкап', source: :sidekiq_cron,
                                        time_zone: 'Europe/Moscow')
    expect(schedule.next_run_at).to be > Time.current
  end

  it 'включает и отключает' do
    scheduler.disable('default/backup')
    expect(scheduler.find('default/backup')).to have_attributes(enabled: false, next_run_at: nil)

    scheduler.enable('default/backup')
    expect(scheduler.find('default/backup')).to be_enabled
  end

  it 'ставит в очередь сейчас' do
    expect { scheduler.enqueue_now('default/backup') }.to change { Sidekiq::Queue.new('backup').size }.by(1)
  end

  it 'на неизвестный id отвечает ArgumentError' do
    expect { scheduler.disable('default/nope') }.to raise_error(ArgumentError)
  end
end
