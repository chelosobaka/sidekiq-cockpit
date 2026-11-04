# Только для dummy-приложения: открыть страницу всем.
SidekiqCockpit.configure do |c|
  c.authorize { true }
  c.back_url = '/'
end
