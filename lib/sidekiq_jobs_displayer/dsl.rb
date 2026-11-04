module SidekiqJobsDisplayer
  # Метаданные задачи прямо в её классе:
  #
  #   class BackupJob
  #     include Sidekiq::Job
  #     include SidekiqJobsDisplayer::Job
  #
  #     displayer description: 'Бэкап базы', trigger: 'кнопка в админке', group: 'Бэкапы',
  #               runnable: true, confirm: 'Запустить бэкап?',
  #               args: [{ name: :chat_id, type: :integer, optional: true }]
  #   end
  #
  # Без displayer тексты берутся из I18n: sidekiq_jobs_displayer.jobs.<backup_job>.description.
  module Job
    OPTIONS = %i[description trigger group runnable confirm args].freeze
    ARG_TYPES = %i[string integer float boolean json].freeze

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def displayer(**options)
        unknown = options.keys - OPTIONS
        raise ArgumentError, "displayer: неизвестные ключи #{unknown.join(', ')}" if unknown.any?

        Array(options[:args]).each do |arg|
          raise ArgumentError, "displayer args: нужен name у #{arg.inspect}" unless arg[:name]
          next if arg[:type].nil? || ARG_TYPES.include?(arg[:type])

          raise ArgumentError, "displayer args: тип #{arg[:type].inspect}, ожидается #{ARG_TYPES.join(', ')}"
        end

        @sidekiq_jobs_displayer_options = options.freeze
      end

      def sidekiq_jobs_displayer_options
        return @sidekiq_jobs_displayer_options if @sidekiq_jobs_displayer_options

        superclass.respond_to?(__method__) ? superclass.sidekiq_jobs_displayer_options : {}
      end
    end
  end
end
