module SidekiqCockpit
  # Метаданные задачи прямо в её классе:
  #
  #   class BackupJob
  #     include Sidekiq::Job
  #     include SidekiqCockpit::Job
  #
  #     cockpit description: 'Бэкап базы', trigger: 'кнопка в админке', group: 'Бэкапы',
  #               runnable: true, confirm: 'Запустить бэкап?',
  #               args: [{ name: :chat_id, type: :integer, optional: true }]
  #   end
  #
  # Без cockpit тексты берутся из I18n: sidekiq_cockpit.jobs.<backup_job>.description.
  module Job
    OPTIONS = %i[description trigger group runnable confirm args].freeze
    ARG_TYPES = %i[string integer float boolean json].freeze

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def cockpit(**options)
        unknown = options.keys - OPTIONS
        raise ArgumentError, "cockpit: неизвестные ключи #{unknown.join(', ')}" if unknown.any?

        Array(options[:args]).each do |arg|
          raise ArgumentError, "cockpit args: нужен name у #{arg.inspect}" unless arg[:name]
          next if arg[:type].nil? || ARG_TYPES.include?(arg[:type])

          raise ArgumentError, "cockpit args: тип #{arg[:type].inspect}, ожидается #{ARG_TYPES.join(', ')}"
        end

        @sidekiq_cockpit_options = options.freeze
      end

      def sidekiq_cockpit_options
        return @sidekiq_cockpit_options if @sidekiq_cockpit_options

        superclass.respond_to?(__method__) ? superclass.sidekiq_cockpit_options : {}
      end
    end
  end
end
