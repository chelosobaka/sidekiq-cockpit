RSpec.describe 'Разметка без CSS-фреймворка', type: :request do
  before do
    SidekiqCockpit.runs_store.record(build_run(status: 'failed', error_class: 'RuntimeError', error_message: 'SSH'))
    create_cron if CRON
  end

  %w[/admin/sidekiq /admin/sidekiq/jobs/BackupJob].each do |path|
    it "#{path}: ни одного class и ни одной ссылки на стили" do
      get path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to match(/\bclass=/)
      expect(response.body).not_to match(/stylesheet|bootstrap/i)
    end
  end

  it 'оставляет data-атрибуты как точки для стилей' do
    get '/admin/sidekiq/jobs/BackupJob'

    expect(response.body).to include('data-status="failed"', 'data-error')
  end

  it 'вьюхи приложения перекрывают вьюхи гема' do
    view_path = Rails.root.join('tmp/override_views')
    FileUtils.mkdir_p(view_path.join('sidekiq_cockpit/runs'))
    File.write(view_path.join('sidekiq_cockpit/runs/_result.html.erb'), '<b>свой итог</b>')
    SidekiqCockpit::JobsController.prepend_view_path(view_path)

    get '/admin/sidekiq/jobs/BackupJob'

    expect(response.body).to include('<b>свой итог</b>')
  ensure
    SidekiqCockpit::JobsController.view_paths = SidekiqCockpit::JobsController.view_paths.reject do |path|
      path.to_s == view_path.to_s
    end
    FileUtils.rm_rf(view_path)
  end
end
