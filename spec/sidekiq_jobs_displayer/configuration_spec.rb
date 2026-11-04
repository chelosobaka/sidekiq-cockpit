RSpec.describe SidekiqJobsDisplayer::Configuration do
  subject(:config) { described_class.new }

  it 'без authorize не пускает никого' do
    expect(config.authorized?(:controller, :read)).to be(false)
  end

  it 'передаёт в authorize контроллер и действие' do
    config.authorize { |_controller, action| action == :read }

    expect(config.authorized?(:controller, :read)).to be(true)
    expect(config.authorized?(:controller, :toggle)).to be(false)
  end

  it 'принимает authorize с одним аргументом' do
    config.authorize { |controller| controller == :admin }

    expect(config.authorized?(:admin, :toggle)).to be(true)
  end

  it 'не принимает неизвестное право' do
    config.authorize { true }

    expect { config.authorized?(:controller, :explode) }.to raise_error(ArgumentError)
  end

  it 'проверяет discovery' do
    expect { config.discovery = :magic }.to raise_error(ArgumentError)
  end

  it 'группирует настройки истории, логов и ошибок' do
    expect(config.history.limit).to eq(100)
    expect(config.logs.lines_per_run).to eq(300)
    expect(config.errors.ttl).to eq(30.days)
  end

  it 'берёт часовой пояс из настроек или приложения' do
    expect(config.zone.name).to eq('Europe/Moscow')
    config.time_zone = 'UTC'
    expect(config.zone.name).to eq('UTC')
  end
end
