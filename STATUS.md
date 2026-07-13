# STATUS.md

## Текущий этап: ЭТАП 1 — Дизайн и моковое приложение

Статус: **в работе / ожидает первой зелёной сборки CI и проверки пользователем
на реальном iPhone**.

## Сделано

- [x] Репозиторий и XcodeGen-проект (`project.yml`): таргеты `Luma`,
      `LumaWidgetsExtension`, `LumaTests`.
- [x] Дизайн-система: `LumaColor`, `LumaTypography`, `LumaSpacing`, `LumaGlass`
      (настоящий Liquid Glass API с fallback на Material).
- [x] Моковые доменные модели: `Conversation`, `ChatMessage`, `ToolActionCard`,
      `LocalModel`, `IntelligenceMode`, `ToolPermission`, `MemoryRecord`,
      `ActionLogEntry`, `PerformanceProfile`, `DiagnosticsSnapshot`.
- [x] Навигация: `RootView`, `Route`, `SettingsHubView`.
- [x] Все 15 экранов из ТЗ на моковых данных:
      главный чат, история (асимметричная сетка), конкретный разговор,
      новый/временный диалог, каталог моделей, карточка модели, загрузка
      модели, настройки интеллекта, центр разрешений, память, редактор
      памяти, журнал действий, производительность, диагностика, лицензии.
- [x] Карточки выполненных действий и карточка подтверждения рискованного
      действия (`ToolActionCardView`, `ConfirmationCardView`) — статичный мок.
- [x] Потоковая генерация ответа (симуляция посимвольно), кнопки
      отправки/остановки.
- [x] Live Activity / Dynamic Island: `LumaAgentActivityAttributes`,
      `LumaAgentLiveActivity` со всеми фазами и preview для lock screen,
      compact/expanded/minimal Dynamic Island.
- [x] Светлая и тёмная тема, SwiftUI Preview на всех основных экранах.
- [x] GitHub Actions: `build.yml` (unsigned, без секретов), `tests.yml`,
      `build-signed.yml` (требует секреты, manual dispatch), `release-unsigned.yml`
      (тег `v*` → GitHub Release с IPA).
- [x] Документация: `CLAUDE.md`, `DESIGN.md`, `ARCHITECTURE.md`, `STATUS.md`,
      `CURRENT_TASK.md`, `KNOWN_ISSUES.md`, `README.md`.

## Осознанно не сделано на Этапе 1

- Реальный инференс (llama.cpp/Metal) — только `MockInferenceEngine`-подобная
  симуляция прямо в `ChatView`, без выделенного протокола `LocalInferenceEngine`
  (появится в Этапе 3/5, чтобы не проектировать архитектуру раньше интерфейса,
  который её проверяет).
- Реальные системные разрешения (EventKit/Contacts/Photos) — только UI центра
  разрешений на моках.
- Реальная долговременная память (SwiftData + шифрование) — только UI на
  моковых записях в памяти процесса.
- Реальная загрузка моделей — экран загрузки анимирует прогресс таймером.

## Дальше

1. Дождаться зелёной сборки `build.yml` и артефакта `Luma-unsigned-ipa`.
2. Пользователь устанавливает unsigned IPA на iPhone 15 и проверяет дизайн.
3. Только после подтверждения пользователя — переход к Этапу 2 (SwiftData и
   реальная архитектура данных). См. правило в `CLAUDE.md`: не переходить к
   следующему этапу автоматически.

## История сборок CI

- **2026-07-13** — первая зелёная сборка `Build` (run
  [29276160422](https://github.com/MakrSas/Luma/actions/runs/29276160422),
  коммит `c4bdd33`). Артефакт `Luma-unsigned-ipa` (~288 КБ) доступен в
  Actions artifacts репозитория (срок хранения 30 дней). По пути до зелёной
  сборки исправлены три проблемы CI (см. историю коммитов и
  `KNOWN_ISSUES.md`): область видимости `RiskLevel` между таргетами
  приложения и виджета, лишний параметр `isEnabled` в вызове реального
  `glassEffect` (сигнатура Xcode 26.3 отличалась от предположенной), и имя
  симулятора для тестов (`iPhone 15` больше не в образе раннера — заменено
  на `iPhone 17`).
