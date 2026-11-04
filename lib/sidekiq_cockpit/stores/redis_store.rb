module SidekiqCockpit
  module Stores
    # Общая основа хранилищ: тот же Redis, что у Sidekiq, ключи под config.redis_key_prefix.
    # Ключи и TTL знают только хранилища — остальной код с Redis не работает.
    class RedisStore
      attr_reader :config

      def initialize(config)
        @config = config
      end

      private

      def key(*parts)
        [config.redis_key_prefix, *parts].join(':')
      end

      def redis(&)
        Sidekiq.redis(&)
      end

      def dump(value) = Sidekiq.dump_json(value)

      def load(raw) = Sidekiq.load_json(raw)
    end
  end
end
