module SidekiqJobsDisplayer
  class Engine < ::Rails::Engine
    isolate_namespace SidekiqJobsDisplayer

    # after_initialize — чтобы настройка install_middleware из config/initializers приложения
    # уже была прочитана. Блок configure_server выполняется только в процессе Sidekiq.
    config.after_initialize do
      next unless SidekiqJobsDisplayer.config.install_middleware

      Sidekiq.configure_server do |config|
        config.server_middleware { |chain| chain.add SidekiqJobsDisplayer::Middleware }
      end
    end

    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
