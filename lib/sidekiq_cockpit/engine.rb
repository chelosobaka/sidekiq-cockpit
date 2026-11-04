module SidekiqCockpit
  class Engine < ::Rails::Engine
    isolate_namespace SidekiqCockpit

    # after_initialize — когда настройки из config/initializers приложения уже прочитаны.
    # Блок configure_server выполняется только в процессе Sidekiq.
    config.after_initialize do
      Sidekiq.configure_server do |config|
        config.server_middleware { |chain| chain.add SidekiqCockpit::Middleware::Recorder }
      end
    end

    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
