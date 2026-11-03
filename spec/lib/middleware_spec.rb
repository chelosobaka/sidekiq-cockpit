RSpec.describe SidekiqJobsDisplayer::Middleware do
  let(:middleware) { described_class.new }
  let(:payload) { { 'class' => 'BackupJob', 'args' => [1] } }

  it 'записывает успешный запуск' do
    middleware.call(nil, payload, 'default') { nil }

    run = SidekiqJobsDisplayer::History.runs('BackupJob').first
    expect(run).to have_attributes(status: 'ok', queue: 'default', args: '[1]')
  end

  it 'записывает ошибку и пробрасывает исключение' do
    expect { middleware.call(nil, payload, 'default') { raise ArgumentError, 'boom' } }
      .to raise_error(ArgumentError)

    run = SidekiqJobsDisplayer::History.runs('BackupJob').first
    expect(run).to have_attributes(status: 'failed', error: 'ArgumentError: boom')
  end

  it 'хранит не больше history_limit запусков' do
    SidekiqJobsDisplayer.config.history_limit = 3
    5.times { middleware.call(nil, payload, 'default') { nil } }

    expect(SidekiqJobsDisplayer::History.runs('BackupJob').size).to eq(3)
  end
end
