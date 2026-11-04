require 'bundler/setup'
require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

desc 'Спеки с sidekiq-cron и без него'
task :spec_all do
  sh 'bundle exec rspec'
  sh({ 'BUNDLE_GEMFILE' => File.expand_path('gemfiles/without_cron.gemfile', __dir__) }, 'bundle exec rspec')
end

task default: :spec_all
