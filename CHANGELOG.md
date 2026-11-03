# Changelog

## 0.1.0 — не выпущен

- Скелет engine: страница «Задачи» (по расписанию / по событиям), страница задачи с историей
  запусков, кнопки sidekiq-cron «Запустить сейчас» / «Включить» / «Отключить».
- Middleware истории запусков в Redis (перенесена из lib/job_history.rb проекта oasis).
- Генератор `rails g sidekiq_jobs_displayer:install`.
