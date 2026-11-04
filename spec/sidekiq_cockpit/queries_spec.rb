RSpec.describe SidekiqCockpit::Queries do
  let(:store) { SidekiqCockpit.runs_store }

  describe SidekiqCockpit::Queries::Overview do
    it 'без расписаний всё — по событиям, с последним запуском и счётчиками' do
      SidekiqCockpit.config.scheduler = :none
      store.record(build_run(jid: 'old'))
      store.record(build_run(jid: 'new', status: 'failed', error_class: 'E'))

      result = described_class.new.call
      expect(result.scheduled).to be_empty
      backup = result.events.find { |row| row.name == 'BackupJob' }
      expect(backup.last_run.jid).to eq('new')
      expect(backup.day_stats).to have_attributes(total: 2, failed: 1)
    end

    it 'фильтрует по группе и по ошибкам' do
      SidekiqCockpit.config.scheduler = :none
      store.record(build_run(job_class: 'ReportJob', status: 'failed', error_class: 'E'))

      expect(described_class.new.call(group: 'Бэкапы').rows.map(&:name)).to eq(['BackupJob'])
      expect(described_class.new.call(failed_only: true).rows.map(&:name)).to eq(['ReportJob'])
    end

    it 'задачи с расписанием — в своём разделе', :cron do
      create_cron

      result = described_class.new.call
      expect(result.scheduled.map(&:name)).to eq(['BackupJob'])
      expect(result.capabilities).to include(:toggle, :enqueue_now)
    end
  end

  describe SidekiqCockpit::Queries::JobDetails do
    it 'отдаёт запуски и почасовые счётчики' do
      store.record(build_run)

      details = described_class.new.call('BackupJob')
      expect(details.runs.size).to eq(1)
      expect(details.hourly.size).to eq(24)
      expect(details.day_stats.total).to eq(1)
    end

    it 'на неизвестную задачу отвечает nil' do
      expect(described_class.new.call('NopeJob')).to be_nil
    end
  end
end
