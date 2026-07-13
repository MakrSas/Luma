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
- **Этап 3 (агент и инструменты)**: `LocalInferenceEngine` (протокол,
  `Luma/Inference/LocalInferenceEngine.swift`) реализован раньше графика —
  см. раздел «Реальный локальный инференс» ниже. `MockInferenceEngine` /
  `MLXInferenceEngine`; `AgentRunCoordinator`,
  `AgentStateMachine`, `ComplexityRouter`, `Planner`, `ToolRegistry`,
  `ToolExecutor`, `ToolCallParser`, `PermissionPolicy`,
  `ConfirmationCoordinator`, `ModelContextBuilder`, `AgentRunStore`,
  `RetryPolicy`, `LoopProtection`. Сюда же относится реальный выбор
  представления ответа (обычный текст / `RichAnswerCard` / один или
  несколько `AnswerWidget`) на основе структуры результата инструмента —
  на Этапе 1 это делает ключевыми словами `MockReplyGenerator` в
  `ChatView.swift`, но сам каталог виджетов (`Luma/Models/AnswerWidget.swift`,
  `Luma/Screens/Chat/AnswerWidgetView.swift`) уже настоящий, не мок.
- **Этап 4 (память)**: `MemoryStore`, `MemoryExtractor`, `MemoryRetriever`,
  `MemoryRanker`, `MemoryDeduplicator`, `MemoryPolicy`,
  `MemoryContextBuilder`, `MemoryEncryption` (Keychain-backed), `MemoryImportExport`,
  `EmbeddingProvider`.
- **Этап 5 (локальная модель)**: базовый реальный инференс уже есть (см.
  ниже) — остаётся полноценный манифест каталога (встроенный + удалённый
  JSON) и возобновляемая многофайловая загрузка со сверкой прогресса по
  каждому файлу.

## Реальный локальный инференс (внедрён раньше графика)

По прямому запросу пользователя проверить виджеты «в реальности», а не на
моках, часть Этапа 5 сделана сразу после Этапа 1, не дожидаясь Этапов 2–4.
Это осознанное отступление от «не пытайся сделать все этапы сразу» —
масштаб сознательно ограничен только инференсом и загрузкой одной модели,
без полного `AgentRunCoordinator`/`Planner`/`ToolRegistry` из Этапа 3.

**Рантайм — MLX, не llama.cpp.** Исходный план называл
`LlamaInferenceEngine` через llama.cpp/GGUF. При подключении
[`LocalLLMClient`](https://github.com/tattn/LocalLLMClient) (SPM,
MIT) обнаружился **подтверждённый открытый баг апстрима** в его
llama.cpp-бэкенде: `LocalLLMClientLlamaC` содержит symlink'и на
git submodule `exclude/llama.cpp`, а SPM никогда не подтягивает submodules
у зависимостей — сборка падает у любого потребителя пакета, не только у
Luma ([issue #94](https://github.com/tattn/LocalLLMClient/issues/94),
подтверждено контрибьютором пакета, решения нет). Переключились на MLX-бэкенд
того же пакета (`LocalLLMClientMLX`) — чистый Swift/Metal, без C++-обёрток
вокруг стороннего submodule, работает нативно на Apple Silicon (все iPhone
с поддержкой Metal, включая iPhone 15/A16).

Из этого следует: модели теперь в формате MLX (папка с
`model.safetensors` + `tokenizer.json` + конфиги), а не одиночный `.gguf`
файл — см. `Luma/Models/LocalModel.swift`. Каталог моделей указывает на
репозитории `mlx-community` на HuggingFace, не на GGUF-файлы.

- `Luma/Inference/LocalInferenceEngine.swift` — протокол
  (`load`/`unload`/`generate`/`cancelGeneration`), `InferenceRequest`,
  `InferenceError`.
- `Luma/Inference/MockInferenceEngine.swift` — для Preview/тестов и как
  явное состояние «модель не скачана» (не смешивается с реальным ответом).
- `Luma/Inference/MLXInferenceEngine.swift` — обёртка над
  `LocalLLMClientMLX.MLXClient`, потоковая генерация.

Если апстрим когда-нибудь починит `LocalLLMClientLlamaC` (issue #94), можно
будет добавить `LlamaInferenceEngine` как альтернативный бэкенд для
GGUF-моделей, не трогая протокол `LocalInferenceEngine`.
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
