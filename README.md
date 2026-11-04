# sidekiq_jobs_displayer

Своя страница фоновых задач Sidekiq для Rails 7.1+ вместо стандартного дашборда:
мониторинг, управление запусками, логи с акцентом на ошибки. Вёрстка на Bootstrap 5.

> Статус: 0.1.0, шаг 1 из 4 — ядро. Есть список задач, страница задачи, история и
> почасовые счётчики, управление расписаниями. Логи и ошибки — шаг 2, ручной запуск с
> аргументами, Retry/Dead и аудит — шаг 3.

## Требования

- Ruby >= 3.2, Rails 7.1 или 7.2, Sidekiq 7
- Необязательно: sidekiq-cron 2 — тогда появляется раздел «По расписанию»

## Установка

```ruby
# Gemfile
gem 'sidekiq_jobs_displayer', github: 'chelosobaka/sidekiq_jobs_displayer'
```

```sh
bundle install
bin/rails g sidekiq_jobs_displayer:install   # initializer + mount в routes.rb
```

```ruby
# config/routes.rb
mount SidekiqJobsDisplayer::Engine => '/admin/sidekiq'
```

Без `c.authorize` страница отвечает 403. Все изменяющие запросы идут через POST с CSRF.

## Как устроено

```
lib/sidekiq_jobs_displayer/
  configuration.rb        все настройки (history, logs, errors — вложенные группы)
  dsl.rb                  include SidekiqJobsDisplayer::Job + displayer ...
  job_definition.rb       одна задача: класс, метаданные, расписания
  registry.rb             каталог задач: классы приложения + расписания + история
  schedulers/             адаптеры расписаний: base (интерфейс), none, sidekiq_cron
  stores/                 Redis: runs (запуски и часовые счётчики)
  middleware/recorder.rb  серверная middleware, пишет итог каждого запуска
  log_sources.rb          интерфейс источников логов (:capture, :file, свой класс)
  queries/                данные для страниц: overview, job_details
  actions/                команды: enqueue_schedule, toggle_schedule
app/                      контроллеры и вьюхи — только Queries и Actions
```

Слои не смешиваются: интерфейс читает через `Queries` и меняет через `Actions`, с Redis
работают только `Stores`, с sidekiq-cron — только `Schedulers::SidekiqCron`.

### Метаданные задачи

```ruby
class BackupJob
  include Sidekiq::Job
  include SidekiqJobsDisplayer::Job

  displayer description: 'Бэкап базы', trigger: 'кнопка в админке', group: 'Бэкапы',
            runnable: true, confirm: 'Запустить бэкап?',
            args: [{ name: :chat_id, type: :integer, optional: true }]
end
```

Без `displayer` тексты берутся из I18n приложения:

```yaml
ru:
  sidekiq_jobs_displayer:
    jobs:
      backup_job:
        description: "Бэкап базы"
        trigger: "кнопка в админке"
```

Для задач по расписанию описание можно взять и из `description` в sidekiq-cron.

### Свой планировщик

```ruby
class MyScheduler < SidekiqJobsDisplayer::Schedulers::Base
  def capabilities = %i[toggle]
  def schedules = [...]   # SidekiqJobsDisplayer::Schedulers::Schedule
  def enable(id) = ...
  def disable(id) = ...
end

SidekiqJobsDisplayer.configure { |c| c.scheduler = MyScheduler }
```

Интерфейс показывает только кнопки из `capabilities`.

### Хранилище

Тот же Redis, что у Sidekiq, префикс `sjd:`. Миграций нет.

| Ключ | Тип | Что | Срок |
|---|---|---|---|
| `sjd:runs:<Class>` | list | последние запуски с jid | `history.limit` |
| `sjd:stats:<Class>:<час>` | hash | ok / failed / interrupted / ms | `history.stats_ttl` |
| `sjd:jobs` | set | все запускавшиеся классы | — |

## Разработка

```sh
bundle install
BUNDLE_GEMFILE=gemfiles/without_cron.gemfile bundle install
redis-server &              # спеки ходят в настоящий Redis (REDIS_URL, по умолчанию db 15)
bundle exec rake            # спеки с sidekiq-cron и без него
bundle exec rubocop
```

Dummy-приложение для спек — `spec/dummy`.
