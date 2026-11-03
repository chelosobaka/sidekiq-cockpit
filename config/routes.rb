SidekiqJobsDisplayer::Engine.routes.draw do
  # Внутри mount: /admin/jobs — все задачи, /admin/jobs/BackupJob — одна задача.
  resources :jobs, path: '', only: %i[index show], param: :name, constraints: { name: %r{[^/]+} } do
    member do
      post :enqueue # sidekiq-cron: поставить в очередь сейчас
      post :enable
      post :disable
    end
  end

  root 'jobs#index'
end
