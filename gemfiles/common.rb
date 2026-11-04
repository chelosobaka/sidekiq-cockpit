# Общие зависимости для разработки. Подключаются из Gemfile (с sidekiq-cron) и
# gemfiles/without_cron.gemfile (без него).
gem 'puma'
gem 'rake'
gem 'rspec-rails', '~> 6.1'
gem 'rubocop', require: false
gem 'rubocop-rails', require: false
gem 'rubocop-rspec', require: false
