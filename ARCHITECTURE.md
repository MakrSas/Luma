# ARCHITECTURE.md

## Структура репозитория

```
Luma/                       — исходники приложения (таргет Luma)
  App/                       LumaApp (@main), AppState (@Observable, корень моковых данных)
  DesignSystem/              LumaColor, LumaTypography, LumaSpacing, LumaGlass
  Models/                    Моковые доменные модели (Conversation, LocalModel, ...)
  Navigation/                Route, RootView, SettingsHubView
  Screens/                   По одной папке на экран/группу экранов
    Chat/                    Главный экран + конкретный разговор (одна и та же ChatView)
    History/                 Асимметричная сетка истории (MasonryLayout)
    Models/                  Каталог, карточка модели, экран загрузки
    Intelligence/             Настройки режима интеллекта
    Permissions/              Центр разрешений
    Memory/                   Список памяти + редактор записи
    ActionLog/                 Журнал выполненных действий
    Performance/               Настройки производительности
    Diagnostics/                Диагностика
    Licenses/                   Лицензии моделей
  Shared/                    Код, общий с таргетом расширения (LumaActivityAttributes)
  Resources/                 Info.plist/entitlements генерируются XcodeGen из project.yml

LumaWidgets/                 Таргет расширения Live Activity / WidgetKit
LumaTests/                   Unit-тесты (XCTest)
project.yml                  Описание проекта для XcodeGen (единственный источник истины
                              о таргетах, схемах, Info.plist и entitlements)
.github/workflows/           CI: build.yml, tests.yml, build-signed.yml, release-unsigned.yml
```

## Почему XcodeGen

Пользователь не имеет современного Mac и не может открыть Xcode локально —
весь `.xcodeproj` генерируется из `project.yml` на CI перед сборкой. **Не
коммитить `.xcodeproj` в репозиторий** — он в `.gitignore`, генерируется заново
каждый раз через `xcodegen generate`. Любое изменение состава таргетов,
Info.plist-ключей или entitlements делается в `project.yml`, а не руками в
Xcode.

## Состояние на Этапе 1

`AppState` (`Luma/App/AppState.swift`) — единственный источник состояния,
`@Observable`, инициализируется моковыми данными из `Models/*.mock*`. Экраны
читают и пишут в `AppState` напрямую через `@Environment(AppState.self)`.
Реального агента, реального инференса и реального доступа к системным данным
нет — это сознательное ограничение Этапа 1 (см. `STATUS.md`).

Навигация — один `NavigationStack` с `NavigationPath` и типизированным `Route`
(`Luma/Navigation/Route.swift`), без табов: это соответствует принципу
управления одной рукой и небольшому объёму постоянного chrome.

## План на следующие этапы (ещё не реализовано)

Эти типы упомянуты в исходном ТЗ и будут введены на соответствующих этапах —
сейчас в коде их нет, чтобы не тратить время Этапа 1 на архитектуру без
интерфейса, который её проверяет:

- **Этап 2 (данные)**: SwiftData-модели взамен моковых структур, миграция
  `AppState` на репозитории поверх `ModelContext`.
- **Этап 3 (агент и инструменты)**: `LocalInferenceEngine` (протокол) +
  `MockInferenceEngine` / `LlamaInferenceEngine`; `AgentRunCoordinator`,
  `AgentStateMachine`, `ComplexityRouter`, `Planner`, `ToolRegistry`,
  `ToolExecutor`, `ToolCallParser`, `PermissionPolicy`,
  `ConfirmationCoordinator`, `ModelContextBuilder`, `AgentRunStore`,
  `RetryPolicy`, `LoopProtection`.
- **Этап 4 (память)**: `MemoryStore`, `MemoryExtractor`, `MemoryRetriever`,
  `MemoryRanker`, `MemoryDeduplicator`, `MemoryPolicy`,
  `MemoryContextBuilder`, `MemoryEncryption` (Keychain-backed), `MemoryImportExport`,
  `EmbeddingProvider`.
- **Этап 5 (локальная модель)**: `LlamaInferenceEngine` через llama.cpp/Metal,
  реальный каталог с манифестом (встроенный + удалённый JSON), проверка
  SHA-256, возобновляемая загрузка.
- **Этап 6 (Dynamic Island и фон)**: реальные `Activity<LumaAgentActivityAttributes>`
  из приложения, `BackgroundTasks` для возобновления приостановленных
  `AgentRun`.
- **Этап 7**: оптимизация под 6 ГБ ОЗУ, полное покрытие тестами.

## Тесты

`LumaTests` — XCTest, таргетируется на `Luma` через `@testable import Luma`.
На Этапе 1 тесты проверяют только моковые данные и `AppState` (см.
`LumaTests/LumaTests.swift`). Запускаются в CI (`tests.yml`, а также как шаг
внутри `build.yml`) на симуляторе `iPhone 17` (см. `KNOWN_ISSUES.md` про
подверженность имени симулятора изменениям линейки).
