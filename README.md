# sidekiq_jobs_displayer

Своя страница фоновых задач для Rails 7 вместо дашборда Sidekiq: все задачи приложения —
**по расписанию** (sidekiq-cron) и **по событиям** — с описанием, расписанием, следующим и
последним запуском, итогом и числом запусков и ошибок за сутки. По задаче — история последних
запусков и кнопки «Запустить сейчас» / «Включить» / «Отключить». Вёрстка — Bootstrap 5.

> Статус: скелет (0.1.0). Работает база, перенесённая из вкладки «Задачи» проекта oasis.

## Требования

- Ruby >= 3.1, Rails 7.x
- Sidekiq 7, sidekiq-cron 2

## Установка

```ruby
# Gemfile
gem 'sidekiq_jobs_displayer', github: 'chelosobaka/sidekiq_jobs_displayer'
```

```sh
bundle install
bin/rails g sidekiq_jobs_displayer:install            # initializer + mount в routes.rb
```

Генератор добавит в `config/routes.rb`:

```ruby
mount SidekiqJobsDisplayer::Engine => '/admin/jobs'
```

Страницу стоит закрыть: либо `config.authorize` в initializer, либо `authenticate`/`constraints`
вокруг `mount`.

## Описания задач

Описание берётся из `description` в расписании sidekiq-cron (`config/schedule.yml`), а если его
нет — из I18n приложения. Там же — человеческая подпись «когда запускается»:

```yaml
ru:
  sidekiq_jobs_displayer:
    jobs:
      backup_job:
        description: "Бэкап серверов, подписок и базы"
        schedule: "в 00:00 и 12:00"        # для задач по расписанию
      telegram_send_message_job:
        description: "Отправляет сообщение клиенту в Telegram"
        trigger: "чеки, напоминания, рассылки" # для задач по событиям
```

## История запусков

Sidekiq выполненные задачи не хранит, поэтому гем ставит серверную middleware
(`SidekiqJobsDisplayer::Middleware`), которая после каждого запуска пишет в Redis время, длительность,
очередь, аргументы и итог (`ok` / `failed` / `interrupted`). По каждой задаче хранится
`config.history_limit` последних запусков в списке `sidekiq_jobs_displayer:history:<Класс>`.

## Настройки

См. `config/initializers/sidekiq_jobs_displayer.rb` после генератора и
`lib/sidekiq_jobs_displayer/configuration.rb`.

## Разработка

```sh
bundle install
redis-server &          # спеки ходят в настоящий Redis (REDIS_URL, по умолчанию localhost:6379/15)
bundle exec rspec
```

Dummy-приложение для спек — `spec/dummy`.
