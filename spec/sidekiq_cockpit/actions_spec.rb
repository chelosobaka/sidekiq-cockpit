RSpec.describe SidekiqCockpit::Actions do
  let(:scheduler) { instance_double(SidekiqCockpit::Schedulers::Base, enable: true, disable: true, enqueue_now: true) }

  it 'включает и отключает расписание через адаптер' do
    SidekiqCockpit::Actions::ToggleSchedule.call(schedule_id: 'x', enabled: false, scheduler: scheduler)
    result = SidekiqCockpit::Actions::ToggleSchedule.call(schedule_id: 'x', enabled: true, scheduler: scheduler)

    expect(scheduler).to have_received(:disable).with('x')
    expect(scheduler).to have_received(:enable).with('x')
    expect(result).to be_ok
  end

  it 'проверяет право, если вызвано из контроллера' do
    SidekiqCockpit.config.authorize { |_controller, action| action == :read }

    expect do
      SidekiqCockpit::Actions::EnqueueSchedule.call(schedule_id: 'x', scheduler: scheduler, controller: :ctrl)
    end.to raise_error(SidekiqCockpit::Actions::Forbidden)
    expect(scheduler).not_to have_received(:enqueue_now)
  end

  it 'неподдерживаемое адаптером — неуспешный результат, а не исключение' do
    result = SidekiqCockpit::Actions::ToggleSchedule.call(
      schedule_id: 'x', enabled: true, scheduler: SidekiqCockpit::Schedulers::None.new
    )

    expect(result).not_to be_ok
  end
end
