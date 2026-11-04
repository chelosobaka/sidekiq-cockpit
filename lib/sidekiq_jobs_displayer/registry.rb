module SidekiqJobsDisplayer
  # Каталог задач. Полный список собирается из трёх источников:
  #   1. классы приложения (config.discovery: :paths — файлы *_job.rb в config.job_paths,
  #      :descendants — все загруженные классы с Sidekiq::Job и наследники ActiveJob::Base);
  #   2. расписания от адаптера;
  #   3. история запусков — так в списке оказываются задачи из других гемов.
  # Минус config.ignore_jobs.
  class Registry
    MODULE_NAME = Module.instance_method(:name)

    def initialize(config:, scheduler:, runs_store:)
      @config = config
      @scheduler = scheduler
      @runs_store = runs_store
    end

    def all
      schedules = @scheduler.schedules.group_by(&:job_class)
      names = (discovered_names + schedules.keys + @runs_store.known_job_classes).uniq - ignored
      names.sort.map { |name| JobDefinition.new(name, schedules: schedules.fetch(name, [])) }
    end

    def find(name)
      all.find { |definition| definition.name == name }
    end

    private

    def ignored
      @config.ignore_jobs.map(&:to_s)
    end

    def discovered_names
      @config.discovery == :descendants ? descendant_names : path_names
    end

    def path_names
      return [] unless defined?(Rails.root) && Rails.root

      @config.job_paths.flat_map do |dir|
        root = Rails.root.join(dir)
        root.glob('**/*_job.rb').map { |path| path.relative_path_from(root).to_s.delete_suffix('.rb').camelize }
      end
    end

    def descendant_names
      Rails.application.eager_load! if defined?(Rails.application) && !Rails.application.config.eager_load
      # Sidekiq::Job > klass, а не klass.include?: чужие классы бывают с переопределённым include?.
      sidekiq = ObjectSpace.each_object(Class).select { |klass| Sidekiq::Job > klass } # rubocop:disable Style/YodaCondition
      active_job = defined?(ActiveJob::Base) ? ActiveJob::Base.descendants : []
      names = (sidekiq + active_job).filter_map { |klass| MODULE_NAME.bind_call(klass) }
      names.reject { |name| name.start_with?('Sidekiq::', 'ActiveJob::') }
    end
  end
end
