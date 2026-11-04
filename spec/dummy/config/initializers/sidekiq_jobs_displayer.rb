# Только для dummy-приложения: открыть страницу всем.
SidekiqJobsDisplayer.configure do |c|
  c.authorize { true }
  c.back_url = '/'
end
