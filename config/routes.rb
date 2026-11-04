SidekiqCockpit::Engine.routes.draw do
  # Обзор (ошибки, очереди) появится на шаге 2, пока корень — список задач.
  root 'jobs#index'

  resources :jobs, only: %i[index show], param: :name, constraints: { name: %r{[^/]+} }

  # id расписания у sidekiq-cron — "namespace/name", поэтому со слэшем.
  scope 'schedules/*id', constraints: { id: /.+/ }, format: false do
    post 'enable', to: 'schedules#enable', as: :enable_schedule
    post 'disable', to: 'schedules#disable', as: :disable_schedule
    post 'enqueue', to: 'schedules#enqueue', as: :enqueue_schedule
  end
end
