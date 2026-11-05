require 'generators/sidekiq_cockpit/install/install_generator'

RSpec.describe 'Генераторы' do
  let(:destination) { Dir.mktmpdir }
  let(:views) { Dir.glob('**/*.erb', base: File.join(destination, 'app/views')).sort }

  after { FileUtils.remove_entry(destination) }

  def run_generator(klass, args = [])
    capture = StringIO.new
    $stdout = capture
    klass.start(args, destination_root: destination)
  ensure
    $stdout = STDOUT
  end

  it 'sidekiq_cockpit:views копирует все вьюхи и лейаут' do
    run_generator(SidekiqCockpit::Generators::ViewsGenerator)

    expect(views).to include('layouts/sidekiq_cockpit/application.html.erb', 'sidekiq_cockpit/jobs/index.html.erb',
                             'sidekiq_cockpit/runs/_result.html.erb', 'sidekiq_cockpit/schedules/_buttons.html.erb')
  end

  it 'sidekiq_cockpit:views копирует только выбранные каталоги и может без лейаута' do
    run_generator(SidekiqCockpit::Generators::ViewsGenerator, %w[runs --skip-layout])

    expect(views).to eq(['sidekiq_cockpit/runs/_result.html.erb'])
  end

  it 'sidekiq_cockpit:install создаёт initializer, mount и вьюхи' do
    FileUtils.mkdir_p(File.join(destination, 'config'))
    File.write(File.join(destination, 'config/routes.rb'), "Rails.application.routes.draw do\nend\n")

    run_generator(SidekiqCockpit::Generators::InstallGenerator)

    expect(File).to exist(File.join(destination, 'config/initializers/sidekiq_cockpit.rb'))
    expect(File.read(File.join(destination,
                               'config/routes.rb'))).to include("mount SidekiqCockpit::Engine => '/admin/sidekiq'")
    expect(views).to include('sidekiq_cockpit/jobs/show.html.erb')
  end

  it 'sidekiq_cockpit:install --skip-views не трогает вьюхи' do
    FileUtils.mkdir_p(File.join(destination, 'config'))
    File.write(File.join(destination, 'config/routes.rb'), "Rails.application.routes.draw do\nend\n")

    run_generator(SidekiqCockpit::Generators::InstallGenerator, ['--skip-views'])

    expect(views).to be_empty
  end
end
