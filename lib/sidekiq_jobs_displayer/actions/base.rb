module SidekiqJobsDisplayer
  module Actions
    class Forbidden < SidekiqJobsDisplayer::Error; end

    # Команда управления. Один публичный метод #call: проверить право, выполнить, вернуть
    # Result. Контроллеры только вызывают действия, поэтому их же можно звать из консоли или
    # бота (без controller — проверка прав пропускается, консоль считается доверенной).
    #
    # Аудит (Stores::Audit) — шаг 3 плана; сюда он встанет в #call.
    class Base
      Result = Data.define(:ok, :message) do
        def ok? = ok
      end

      class << self
        attr_reader :permission

        def requires(permission)
          @permission = permission
        end

        def call(...) = new(...).call
      end

      def initialize(controller: nil, config: SidekiqJobsDisplayer.config)
        @controller = controller
        @config = config
      end

      def call
        authorize!
        perform
      rescue Schedulers::NotSupported, ArgumentError => e
        failure(e.message)
      end

      private

      attr_reader :controller, :config

      def perform = raise(NotImplementedError)

      def authorize!
        return if controller.nil?
        return if config.authorized?(controller, self.class.permission)

        raise Forbidden, self.class.permission.to_s
      end

      def actor = controller && config.actor_for(controller)

      def success(message) = Result.new(ok: true, message: message)

      def failure(message) = Result.new(ok: false, message: message)
    end
  end
end
