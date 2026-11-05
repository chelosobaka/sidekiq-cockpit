require 'rails/generators'

module SidekiqCockpit
  module Generators
    # Копирует вьюхи и лейаут в приложение, чтобы оформить их под свой CSS-фреймворк:
    #
    #   rails g sidekiq_cockpit:views                 # все вьюхи
    #   rails g sidekiq_cockpit:views jobs schedules  # только эти каталоги
    #   rails g sidekiq_cockpit:views --skip-layout   # без лейаута
    #
    # Вьюхи приложения в app/views/sidekiq_cockpit перекрывают вьюхи гема. Это голый HTML:
    # классы Bootstrap 5 оставлены ERB-комментариями как подсказки.
    class ViewsGenerator < Rails::Generators::Base
      source_root File.expand_path('../../../../app/views', __dir__)

      argument :scopes, type: :array, default: [], banner: 'jobs schedules runs'
      class_option :layout, type: :boolean, default: true, desc: 'Скопировать и лейаут'

      def copy_views
        available = Dir.children(File.join(self.class.source_root, 'sidekiq_cockpit')).sort
        unknown = scopes - available
        raise Thor::Error, "Нет каталогов вьюх: #{unknown.join(', ')}. Есть: #{available.join(', ')}" if unknown.any?

        (scopes.presence || available).each do |scope|
          directory "sidekiq_cockpit/#{scope}", "app/views/sidekiq_cockpit/#{scope}"
        end
      end

      def copy_layout
        return unless options[:layout]

        directory 'layouts/sidekiq_cockpit', 'app/views/layouts/sidekiq_cockpit'
      end
    end
  end
end
