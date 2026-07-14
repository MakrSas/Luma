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
  `RetryPolicy`, `LoopProtection`. `ToolRegistry`/`ToolExecutor` уже частично
  есть раньше графика — `Luma/Inference/DeviceTools.swift` (см. «Реальный
  локальный инференс» ниже) — но ограничены тремя инструментами устройства,
  без полноценного реестра, разрешений и подтверждений. Выбор представления
  ответа (обычный текст / `RichAnswerCard` / `AnswerWidget`) на основе
  структуры результата инструмента делает `DeviceToolWidgets` в
  `ChatView.swift` по имени вызванного инструмента (не по ключевым словам
  из сообщения пользователя — это менялось по ходу разработки, см. ниже);
  сам каталог виджетов (`Luma/Models/AnswerWidget.swift`,
  `Luma/Screens/Chat/AnswerWidgetView.swift`) и данные, которые он
  показывает (`DeviceStatusProvider`), настоящие.
- **Этап 4 (память)**: `MemoryStore`, `MemoryExtractor`, `MemoryRetriever`,
  `MemoryRanker`, `MemoryDeduplicator`, `MemoryPolicy`,
  `MemoryContextBuilder`, `MemoryEncryption` (Keychain-backed), `MemoryImportExport`,
  `EmbeddingProvider`.
- **Этап 5 (локальная модель)**: базовый реальный инференс и реальная
  загрузка уже есть (см. ниже) — остаётся полноценный манифест каталога
  (встроенный + удалённый JSON) и настоящее возобновление прерванной
  загрузки на уровне отдельного файла (сейчас «резюме» — на уровне целых
  файлов, см. `KNOWN_ISSUES.md`).
- **Этап 6 (Dynamic Island и фон)**: реальные `Activity<LumaAgentActivityAttributes>`
  из приложения, `BackgroundTasks` для возобновления приостановленных
  `AgentRun`.
- **Этап 7**: оптимизация под 6 ГБ ОЗУ, полное покрытие тестами.

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

MLX-бэкенд тоже не собрался с первой попытки: транзитивная зависимость
`swift-transformers` 1.3.3 (через `Tokenizers`) написана против API
`swift-jinja` до его коммита от 2026-07-13 «Support integer keys in Jinja
object literals» (введён тип `ObjectKey`), выпущенного как версия 2.4.0.
`LocalLLMClient` требует `swift-jinja from: 2.3.5` — без дополнительных
ограничений SPM резолвит его к последней версии (2.4.0), которая ломает
компиляцию `swift-transformers`. Зафиксировано в `project.yml` явным,
не подключённым ни к одному таргету пакетом `SwiftJinja` с диапазоном
`2.3.5...2.3.6` — этого достаточно, чтобы унифицированный резолвер SPM не
поднимался до 2.4.0 для всего графа.

Из этого следует: модели теперь в формате MLX (папка с
`model.safetensors` + `tokenizer.json` + конфиги), а не одиночный `.gguf`
файл — см. `Luma/Models/LocalModel.swift`. Каталог моделей указывает на
репозитории `mlx-community` на HuggingFace, не на GGUF-файлы.

- `Luma/Inference/LocalInferenceEngine.swift` — протокол
  (`load(modelFileURL:tools:)`/`unload`/`generate`/`cancelGeneration`),
  `InferenceRequest`, `InferenceEvent` (`.token`/`.toolCall`), `InferenceError`.
- `Luma/Inference/MockInferenceEngine.swift` — для Preview/тестов и как
  явное состояние «модель не скачана» (не смешивается с реальным ответом).
- `Luma/Inference/DeviceTools.swift` — настоящие `LLMTool`-реализации
  (`get_battery_status`/`get_storage_status`/`get_system_version`), каждая
  читает `DeviceStatusProvider` напрямую. **Модель сама решает**, вызывать
  ли инструмент — это заменило более раннюю версию с сопоставлением по
  ключевым словам (`DeviceIntent`), которую пользователь прямо попросил
  убрать («додумывался сам, а не по шаблону»).
- `Luma/Inference/MLXInferenceEngine.swift` — обёртка над
  `LocalLLMClientMLX.MLXClient`. **Важная деталь реализации**: `MLXClient.
  responseStream` только детектирует вызов инструмента и останавливает
  поток — библиотека не выполняет инструмент и не продолжает генерацию
  сама (проверено по исходникам, скрытого автоцикла нет). `generate`
  реализует небольшой ручной агентный цикл: собрать вызовы инструментов
  из `responseStream`, выполнить их через `AnyLLMTool.call(argumentsJSON:)`,
  передать результаты в `resumeStream(withToolCalls:toolOutputs:
  originalInput:)`, стримить финальный ответ модели, уже опирающийся на
  реальный результат инструмента.
- `Luma/Services/ModelDownloader.swift` — настоящая загрузка каждого файла
  модели с HuggingFace (`resolve/main/<filename>`) через
  `URLSessionDownloadDelegate` с побайтовым прогрессом, с проверкой
  SHA-256 файла весов (`CryptoKit`) против значения из
  `Luma/Models/LocalModel.swift` (взято из HuggingFace API, не выдумано).
  Файлы, уже присутствующие на диске с прошлой прерванной попытки,
  пропускаются — это и есть текущая форма «резюме» (на уровне файла
  целиком, не байтового диапазона — честно зафиксировано как ограничение
  в `KNOWN_ISSUES.md`).
- `Luma/Services/DeviceStatusProvider.swift` — реальные `UIDevice.batteryLevel`/
  `batteryState` и `URLResourceKey.volumeAvailableCapacityForImportantUsageKey`,
  вместо моковых чисел `DiagnosticsSnapshot` — именно эти данные попадают
  в `AnswerWidget`, когда пользователь спрашивает про заряд/память в чате.
- `AppState.init()` сканирует диск (`ModelDownloader.isDownloaded`) и
  проставляет `.installed` тем моделям каталога, что уже скачаны —
  `availableModels` больше не считается чистым моком.

Если апстрим когда-нибудь починит `LocalLLMClientLlamaC` (issue #94), можно
будет добавить `LlamaInferenceEngine` как альтернативный бэкенд для
GGUF-моделей, не трогая протокол `LocalInferenceEngine`.

## Тесты

`LumaTests` — XCTest, таргетируется на `Luma` через `@testable import Luma`.
На Этапе 1 тесты проверяют только моковые данные и `AppState` (см.
`LumaTests/LumaTests.swift`). Запускаются в CI (`tests.yml`, а также как шаг
внутри `build.yml`) на симуляторе `iPhone 17` (см. `KNOWN_ISSUES.md` про
подверженность имени симулятора изменениям линейки).
