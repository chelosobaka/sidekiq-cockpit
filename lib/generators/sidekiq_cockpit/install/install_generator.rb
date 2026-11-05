require 'rails/generators'
require_relative '../views/views_generator'

module SidekiqCockpit
  module Generators
    # rails g sidekiq_cockpit:install [--path=/admin/sidekiq] [--skip-views]
    #
    # Создаёт initializer, монтирует engine и копирует вьюхи в приложение
    # (sidekiq_cockpit:views), чтобы их оформили под свой CSS-фреймворк.
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      class_option :path, type: :string, default: '/admin/sidekiq', desc: 'Куда смонтировать страницу'
      class_option :views, type: :boolean, default: true, desc: 'Скопировать вьюхи в приложение'

      def copy_initializer
        template 'initializer.rb', 'config/initializers/sidekiq_cockpit.rb'
      end

      def mount_engine
        route "mount SidekiqCockpit::Engine => '#{options[:path]}'"
      end

      def copy_views
        invoke ViewsGenerator, [] if options[:views]
      end
    end
  end
end
