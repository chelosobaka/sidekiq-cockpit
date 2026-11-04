RSpec.describe SidekiqJobsDisplayer::Middleware::Recorder do
  let(:recorder) { described_class.new }
  let(:store) { SidekiqJobsDisplayer.runs_store }
  let(:payload) { { 'class' => 'BackupJob', 'jid' => 'abc', 'args' => [1, { 'password' => 'x', 'name' => 'y' }] } }

  it 'записывает успешный запуск с jid и маскирует секреты' do
    recorder.call(nil, payload, 'default') { nil }

    expect(store.runs('BackupJob').sole).to have_attributes(
      jid: 'abc', status: 'ok', queue: 'default', args: '[1,{"password":"[FILTERED]","name":"y"}]'
    )
  end

  it 'записывает ошибку и пробрасывает исключение' do
    expect { recorder.call(nil, payload, 'default') { raise ArgumentError, 'boom' } }.to raise_error(ArgumentError)

    expect(store.runs('BackupJob').sole).to have_attributes(status: 'failed', error_class: 'ArgumentError',
                                                            error_message: 'boom')
  end

  it 'помечает прерванный перезапуском' do
    expect { recorder.call(nil, payload, 'default') { raise Sidekiq::Shutdown } }.to raise_error(Sidekiq::Shutdown)

    expect(store.runs('BackupJob').sole.status).to eq('interrupted')
  end

  it 'у ActiveJob берёт класс и аргументы из обёртки' do
    wrapped = { 'class' => 'Sidekiq::ActiveJob::Wrapper', 'wrapped' => 'ReportJob', 'jid' => 'j',
                'args' => [{ 'job_class' => 'ReportJob', 'arguments' => ['week'] }] }
    recorder.call(nil, wrapped, 'reports') { nil }

    expect(store.runs('ReportJob').sole.args).to eq('["week"]')
  end

  it 'не ломает задачу, если Redis недоступен' do
    allow(store).to receive(:record).and_raise(RedisClient::CannotConnectError)

    expect { recorder.call(nil, payload, 'default') { :done } }.not_to raise_error
  end
end
