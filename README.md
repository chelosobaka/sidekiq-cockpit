# sidekiq-cockpit

Своя страница фоновых задач Sidekiq для Rails 7.1+ вместо стандартного дашборда:
мониторинг, управление запусками, логи с акцентом на ошибки. Вьюхи — голый HTML без
CSS-фреймворка: оформление остаётся за приложением.

> Статус: 0.1.0, шаг 1 из 4 — ядро. Есть список задач, страница задачи, история и
> почасовые счётчики, управление расписаниями. Логи и ошибки — шаг 2, ручной запуск с
> аргументами, Retry/Dead и аудит — шаг 3.

## Требования

- Ruby >= 3.2, Rails 7.1 или 7.2, Sidekiq 7
- Необязательно: sidekiq-cron 2 — тогда появляется раздел «По расписанию»

## Установка

```ruby
# Gemfile
gem 'sidekiq-cockpit', github: 'chelosobaka/sidekiq-cockpit'
```

```sh
bundle install
bin/rails g sidekiq_cockpit:install   # initializer, mount в routes.rb и вьюхи в app/views
```

```ruby
# config/routes.rb
mount SidekiqCockpit::Engine => '/admin/sidekiq'
```

Без `c.authorize` страница отвечает 403. Все изменяющие запросы идут через POST с CSRF.

## Вьюхи и стили

Гем не подключает ни Bootstrap, ни другой CSS: страницы — голый HTML. Генератор `install`
копирует вьюхи и лейаут в приложение (`--skip-views`, чтобы не копировать), а
`sidekiq_cockpit:views` делает это отдельно:

```sh
bin/rails g sidekiq_cockpit:views                 # все вьюхи и лейаут
bin/rails g sidekiq_cockpit:views jobs runs       # только эти каталоги
bin/rails g sidekiq_cockpit:views --skip-layout   # без лейаута
```

Вьюхи из `app/views/sidekiq_cockpit` приложения перекрывают вьюхи гема. В каждом теге
оставлена подсказка, как он выглядел на Bootstrap 5, — ERB-комментарий, который не попадает
в HTML:

```erb
<table <%# class="table table-striped table-hover align-top" %>>
```

Под Bootstrap достаточно снять обёртку комментария (и раскомментировать ссылку на CDN в
лейауте), под другой фреймворк — заменить классы своими. Для стилей без классов в разметке
есть data-атрибуты: `data-status="ok|failed|interrupted"`, `data-error`, `data-section`,
`data-job`, `data-schedule`, `data-enabled`, `data-flash`.

Лейаут можно не копировать, а взять лейаут приложения: `c.layout = 'admin'`.

## Как устроено

```
lib/sidekiq_cockpit/
  configuration.rb        все настройки (history, logs, errors — вложенные группы)
  dsl.rb                  include SidekiqCockpit::Job + cockpit ...
  job_definition.rb       одна задача: класс, метаданные, расписания
  registry.rb             каталог задач: классы приложения + расписания + история
  schedulers/             адаптеры расписаний: base (интерфейс), none, sidekiq_cron
  stores/                 Redis: runs (запуски и часовые счётчики)
  middleware/recorder.rb  серверная middleware, пишет итог каждого запуска
  log_sources.rb          интерфейс источников логов (:capture, :file, свой класс)
  queries/                данные для страниц: overview, job_details
  actions/                команды: enqueue_schedule, toggle_schedule
app/                      контроллеры и вьюхи (голый HTML) — только Queries и Actions
lib/generators/           install и views
```

Слои не смешиваются: интерфейс читает через `Queries` и меняет через `Actions`, с Redis
работают только `Stores`, с sidekiq-cron — только `Schedulers::SidekiqCron`.

### Метаданные задачи

```ruby
class BackupJob
  include Sidekiq::Job
  include SidekiqCockpit::Job

  cockpit description: 'Бэкап базы', trigger: 'кнопка в админке', group: 'Бэкапы',
            runnable: true, confirm: 'Запустить бэкап?',
            args: [{ name: :chat_id, type: :integer, optional: true }]
end
```

Без `cockpit` тексты берутся из I18n приложения:

```yaml
ru:
  sidekiq_cockpit:
    jobs:
      backup_job:
        description: "Бэкап базы"
        trigger: "кнопка в админке"
```

Для задач по расписанию описание можно взять и из `description` в sidekiq-cron.

### Свой планировщик

```ruby
class MyScheduler < SidekiqCockpit::Schedulers::Base
  def capabilities = %i[toggle]
  def schedules = [...]   # SidekiqCockpit::Schedulers::Schedule
  def enable(id) = ...
  def disable(id) = ...
end

SidekiqCockpit.configure { |c| c.scheduler = MyScheduler }
```

Интерфейс показывает только кнопки из `capabilities`.

### Хранилище

Тот же Redis, что у Sidekiq, префикс `cockpit:`. Миграций нет.

| Ключ | Тип | Что | Срок |
|---|---|---|---|
| `cockpit:runs:<Class>` | list | последние запуски с jid | `history.limit` |
| `cockpit:stats:<Class>:<час>` | hash | ok / failed / interrupted / ms | `history.stats_ttl` |
| `cockpit:jobs` | set | все запускавшиеся классы | — |

## Разработка

```sh
bundle install
BUNDLE_GEMFILE=gemfiles/without_cron.gemfile bundle install
redis-server &              # спеки ходят в настоящий Redis (REDIS_URL, по умолчанию db 15)
bundle exec rake            # спеки с sidekiq-cron и без него
bundle exec rubocop
```

Dummy-приложение для спек — `spec/dummy`.
