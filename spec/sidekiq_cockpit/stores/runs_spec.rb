RSpec.describe SidekiqCockpit::Stores::Runs do
  let(:config) { SidekiqCockpit.config }
  let(:store) { described_class.new(config) }

  it 'хранит запуски, новые сверху, и помнит jid' do
    store.record(build_run(jid: 'a'))
    store.record(build_run(jid: 'b', status: 'failed', error_class: 'RuntimeError', error_message: 'boom'))

    runs = store.runs('BackupJob')
    expect(runs.map(&:jid)).to eq(%w[b a])
    expect(runs.first.error).to eq('RuntimeError: boom')
    expect(runs.first.started_at.time_zone.name).to eq('Europe/Moscow')
  end

  it 'обрезает список по history.limit, а счётчики считают всё' do
    config.history.limit = 3
    5.times { store.record(build_run) }

    expect(store.runs('BackupJob').size).to eq(3)
    expect(store.stats('BackupJob').total).to eq(5)
  end

  it 'считает по часам и только за окно' do
    now = Time.current
    store.record(build_run(started_at: now, duration: 1.0))
    store.record(build_run(started_at: now - 2.hours, status: 'failed', error_class: 'E', duration: 3.0))
    store.record(build_run(started_at: now - 30.hours))

    stats = store.stats('BackupJob', now: now)
    expect(stats).to have_attributes(ok: 1, failed: 1, total: 2)
    expect(stats.average_duration).to eq(2.0)

    hourly = store.hourly_by_class(['BackupJob'], hours: 3, now: now).fetch('BackupJob')
    expect(hourly.map { |_, s| s.total }).to eq([1, 0, 1])
  end

  it 'ставит TTL на счётчики' do
    store.record(build_run)

    ttl = Sidekiq.redis { |conn| conn.ttl(conn.scan(match: 'cockpit:stats:*').to_a.first) }
    expect(ttl).to be_within(5).of(48.hours.to_i)
  end

  it 'помнит все запускавшиеся классы и последние запуски' do
    store.record(build_run(job_class: 'AJob', jid: '1'))
    store.record(build_run(job_class: 'BJob', jid: '2'))

    expect(store.known_job_classes).to eq(%w[AJob BJob])
    expect(store.last_runs(%w[AJob CJob]).transform_values { |run| run&.jid }).to eq('AJob' => '1', 'CJob' => nil)
  end

  it 'не принимает неизвестный статус' do
    expect { store.record(build_run(status: 'weird')) }.to raise_error(ArgumentError)
  end
end
