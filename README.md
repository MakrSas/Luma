# Luma

Luma — нативное iOS-приложение: локальный текстовый ИИ-агент для iPhone.
Пользователь пишет запрос, локальная модель понимает его, выбирает доступные
инструменты приложения и выполняет разрешённые действия на телефоне —
подтверждая рискованные операции перед выполнением.

Название Luma относится только к приложению; сам агент не представляется
этим именем.

## Статус

Этап 1 — дизайн и полностью моковое приложение. См. [STATUS.md](STATUS.md) и
[CURRENT_TASK.md](CURRENT_TASK.md).

## Технологии

Swift, SwiftUI, Swift Concurrency, Observation, SwiftData (со Stage 2),
ActivityKit, WidgetKit, App Intents, EventKit, Photos, Contacts, CryptoKit,
Keychain, URLSession, BackgroundTasks. Проект описан через
[XcodeGen](https://github.com/yonaskolb/XcodeGen) (`project.yml`) —
`.xcodeproj` не хранится в репозитории и генерируется на CI.

## Сборка

Локально (на Mac с Xcode):

```sh
brew install xcodegen
xcodegen generate
open Luma.xcodeproj
```

Без Mac — через GitHub Actions:

- `Build` (`.github/workflows/build.yml`) — на каждый пуш/PR в `main`,
  собирает неподписанный IPA без секретов и выкладывает его как artifact.
- `Tests` (`.github/workflows/tests.yml`) — юнит-тесты на PR.
- `Build Signed IPA` (`.github/workflows/build-signed.yml`) — вручную, требует
  секреты подписи (сертификат, provisioning profile, Team ID).
- `Release Unsigned IPA` (`.github/workflows/release-unsigned.yml`) — на тег
  `v*`, публикует IPA как GitHub Release.

## Документация

- [CLAUDE.md](CLAUDE.md) — постоянные правила для работы над проектом.
- [DESIGN.md](DESIGN.md) — утверждённый визуальный язык.
- [ARCHITECTURE.md](ARCHITECTURE.md) — структура кода.
- [KNOWN_ISSUES.md](KNOWN_ISSUES.md) — известные ограничения и риски CI.
