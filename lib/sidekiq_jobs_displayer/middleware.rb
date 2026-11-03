module SidekiqJobsDisplayer
  # Серверная middleware Sidekiq: записывает итог каждого запуска в History. Исключение
  # задачи пробрасывается дальше — повторы и «Убито» работают как обычно.
  class Middleware
    include Sidekiq::ServerMiddleware

    def call(_job, payload, queue)
      started_at = Time.current
      clock = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      yield
      record(payload, queue, started_at, clock, 'ok')
    rescue Sidekiq::Shutdown
      record(payload, queue, started_at, clock, 'interrupted')
      raise
    rescue StandardError => e
      record(payload, queue, started_at, clock, 'failed', e)
      raise
    end

    private

    def record(payload, queue, started_at, clock, status, error = nil)
      duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - clock
      History.record(payload, queue, started_at: started_at, duration: duration, status: status, error: error)
    end
  end
end
