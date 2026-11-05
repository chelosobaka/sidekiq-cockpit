# Changelog

## 0.1.0 — не выпущен

Без привязки к Bootstrap.

- Вьюхи и лейаут — голый HTML: классы Bootstrap 5 оставлены ERB-комментариями как подсказки,
  CDN в лейауте закомментирован. Для стилей есть data-атрибуты.
- Генератор `sidekiq_cockpit:views` копирует вьюхи в приложение; `install` вызывает его сам
  (`--skip-views`).
- Итог запуска рендерится партиалом `runs/_result`, а не хелпером; кнопки расписаний —
  обычные формы вместо `button_to`.
- Убраны настройки `bootstrap_css_url` и `bootstrap_js_url`.

Шаг 1: ядро по слоям.

- `Configuration` с вложенными `history`, `logs`, `errors`; `authorize` получает действие.
- `Registry`, `JobDefinition` и DSL `cockpit` (`include SidekiqCockpit::Job`).
- Адаптеры расписаний `Schedulers::None` и `Schedulers::SidekiqCron` с `capabilities`;
  sidekiq-cron больше не зависимость гема, выбор — `c.scheduler = :auto`.
- `Stores::Runs`: запуски с jid и часовые счётчики `cockpit:stats`.
- `Middleware::Recorder`, маскирование секретов в аргументах.
- `Queries::Overview`, `Queries::JobDetails`, `Actions::ToggleSchedule`, `Actions::EnqueueSchedule`.
- Интерфейс `LogSources` (`:capture`, `:file`, свой класс) — сами источники на шаге 2.
- Rails >= 7.1, Ruby >= 3.2. Спеки на каждый слой, прогон с sidekiq-cron и без него.
