RSpec.describe SidekiqJobsDisplayer::Actions do
  let(:scheduler) { instance_double(SidekiqJobsDisplayer::Schedulers::Base, enable: true, disable: true, enqueue_now: true) }

  it 'включает и отключает расписание через адаптер' do
    SidekiqJobsDisplayer::Actions::ToggleSchedule.call(schedule_id: 'x', enabled: false, scheduler: scheduler)
    result = SidekiqJobsDisplayer::Actions::ToggleSchedule.call(schedule_id: 'x', enabled: true, scheduler: scheduler)

    expect(scheduler).to have_received(:disable).with('x')
    expect(scheduler).to have_received(:enable).with('x')
    expect(result).to be_ok
  end

  it 'проверяет право, если вызвано из контроллера' do
    SidekiqJobsDisplayer.config.authorize { |_controller, action| action == :read }

    expect do
      SidekiqJobsDisplayer::Actions::EnqueueSchedule.call(schedule_id: 'x', scheduler: scheduler, controller: :ctrl)
    end.to raise_error(SidekiqJobsDisplayer::Actions::Forbidden)
    expect(scheduler).not_to have_received(:enqueue_now)
  end

  it 'неподдерживаемое адаптером — неуспешный результат, а не исключение' do
    result = SidekiqJobsDisplayer::Actions::ToggleSchedule.call(
      schedule_id: 'x', enabled: true, scheduler: SidekiqJobsDisplayer::Schedulers::None.new
    )

    expect(result).not_to be_ok
  end
end
