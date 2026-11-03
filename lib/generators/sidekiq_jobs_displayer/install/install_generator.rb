require 'rails/generators'

module SidekiqJobsDisplayer
  module Generators
    # rails g sidekiq_jobs_displayer:install [--path=/admin/jobs]
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      class_option :path, type: :string, default: '/admin/jobs', desc: 'Куда смонтировать страницу'

      def copy_initializer
        template 'initializer.rb', 'config/initializers/sidekiq_jobs_displayer.rb'
      end

      def mount_engine
        route "mount SidekiqJobsDisplayer::Engine => '#{options[:path]}'"
      end
    end
  end
end
