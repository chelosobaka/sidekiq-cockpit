RSpec.describe SidekiqJobsDisplayer::Schedulers do
  it ':auto выбирает sidekiq-cron, если он подключён', :cron do
    expect(described_class.resolve(:auto)).to be_a(described_class::SidekiqCron)
  end

  it ':auto без sidekiq-cron выбирает None', cron: false do
    expect(described_class.resolve(:auto)).to be_a(described_class::None)
  end

  it ':sidekiq_cron без гема — понятная ошибка', cron: false do
    expect { described_class.resolve(:sidekiq_cron) }.to raise_error(SidekiqJobsDisplayer::Error, /не подключён/)
  end

  it 'принимает свой класс и готовый объект' do
    custom = Class.new(described_class::Base)
    instance = custom.new

    expect(described_class.resolve(custom)).to be_a(custom)
    expect(described_class.resolve(instance)).to be(instance)
  end

  it 'None ничего не умеет' do
    none = described_class::None.new

    expect(none.schedules).to eq([])
    expect(none.capabilities).to eq([])
    expect { none.enable('x') }.to raise_error(described_class::NotSupported)
  end
end
