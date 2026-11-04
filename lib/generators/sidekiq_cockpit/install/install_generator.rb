require 'rails/generators'

module SidekiqCockpit
  module Generators
    # rails g sidekiq_cockpit:install [--path=/admin/sidekiq]
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      class_option :path, type: :string, default: '/admin/sidekiq', desc: 'Куда смонтировать страницу'

      def copy_initializer
        template 'initializer.rb', 'config/initializers/sidekiq_cockpit.rb'
      end

      def mount_engine
        route "mount SidekiqCockpit::Engine => '#{options[:path]}'"
      end
    end
  end
end
