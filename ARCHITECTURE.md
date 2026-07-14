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

**Доступ в интернет** (`Luma/Inference/WebTools.swift`,
`Luma/Services/WebSearchService.swift`) — те же принципы, что и у
`DeviceTools`: настоящие `LLMTool`, модель сама решает, вызывать ли их.
`SearchWebTool`/`search_web` бьёт в публичный keyless `opensearch` эндпоинт
Wikipedia (никакого API-ключа не требуется); `FetchURLTool`/`fetch_url`
загружает конкретную страницу и грубо снимает HTML-теги. `ChatView` включает
оба инструмента в список, передаваемый `load(modelFileURL:tools:)`, только
если `ToolPermission` с `toolName == "search_web"` не в состоянии `.denied`
(центр разрешений, `Luma/Models/ToolPermission.swift`) — по умолчанию оба
в состоянии `.ask`. Честное ограничение: `.ask` пока не показывает отдельного
подтверждения на каждый вызов (это `ConfirmationCoordinator` из плана Этапа
3), только общий переключатель «разрешено/спрашивать/запрещено» на уровне
инструмента целиком — см. `KNOWN_ISSUES.md`.

## App-иконка: Liquid Glass / Icon Composer без самого Icon Composer

iOS 26 ввёл новый формат иконки приложения — `.icon`-пакет (папка с
`icon.json` + слоями PNG), который система сама рендерит с бликами,
преломлением и параллаксом (Liquid Glass), вместо одного плоского PNG.
Штатный способ его создать — приложение Icon Composer (часть Xcode 26,
только macOS). У пользователя нет Mac вообще (ни Metal, ни ускорения
графики) — ниже задокументирован полный обходной путь, найденный
методом проб и одной ручной сессии в виртуалке.

### Часть 1 — собрать `.icon`-пакет без Icon Composer.app

Сборка самого `.icon`-пакета (JSON-манифест + PNG-слои) не требует
Icon Composer.app и не требует macOS — нужен только рендеринг **живых**
бликов для предпросмотра, не для сборки файла. Инструмент:
[`icon-composer-mcp`](https://github.com/ethbak/icon-composer-mcp)
(npm-пакет, кроссплатформенный CLI + MCP-сервер).

```bash
# CLI-бинарь называется "icon-composer", а не "icon-composer-mcp" —
# имя пакета и имя бинаря разные, поэтому нужен -p:
npx -y -p icon-composer-mcp icon-composer <команда> ...
```

Рабочий процесс:

1. **Готовите плоский глиф** — просто чёрная (или белая) заливка форма
   на прозрачном PNG, без своих градиентов/бликов/теней. Система сама
   рисует specular/blur/refraction поверх плоской формы в рантайме —
   если дать ей уже «залакированную» картинку (типа хромированного
   варианта), эффекты наложатся друг на друга и будет странно
   выглядеть. Нужны обе версии — тёмная форма (для светлого фона) и
   светлая форма (для тёмного фона), либо одна форма + перекраска через
   `fill-specializations` (см. ниже).
2. **Создать пакет**:
   ```bash
   icon-composer create glyph.png ./out --bg-color "#F7F6F4" --dark-bg-color "#0F0F10"
   ```
   Создаёт `./out/AppIcon.icon/` с `icon.json` + `Assets/foreground.png`,
   с уже правильными `fill-specializations` для фона (light/dark).
3. **Перекрасить глиф под тёмный режим** (сам глиф остаётся тем же PNG,
   перекраска идёт через `fill-color`, не через второе изображение):
   ```bash
   icon-composer appearance ./out/AppIcon.icon --target layer \
     --group-index 0 --layer-index 0 --appearance dark --fill-color "#F7F6F4"
   ```
4. **Подобрать масштаб глифа** (дефолт `--glyph-scale 1.75` при
   `create` — почти всегда слишком много, глиф упирается в края):
   ```bash
   icon-composer position ./out/AppIcon.icon --target layer \
     --group-index 0 --layer-index 0 --scale 1.4
   ```
   Удобно сравнить несколько значений сразу — `preview` рендерит
   плоский превью-PNG (без бликов, но с правильными пропорциями/цветом)
   на любой платформе:
   ```bash
   icon-composer preview ./out/AppIcon.icon preview.png --appearance light --size 180
   ```
5. **Проверить структуру** перед тем как коммитить:
   ```bash
   icon-composer inspect ./out/AppIcon.icon
   ```
   Валидирует JSON и список файлов; не проверяет реальный рендер (это
   уже требует Icon Composer.app + macOS).

### Часть 2 — подключить `.icon`-пакет к Xcode-проекту через XcodeGen

Это была куда более сложная часть — три разных попытки подряд не
работали:

1. `.icon`-папка **внутри** `Assets.xcassets` → `actool` падает:
   `None of the input catalogs contained a matching stickers icon set,
   app icon set, or icon stack named "AppIcon"`.
2. Переименование в `.appiconset` → сборка проходит, но иконка
   пустая — `actool` просто не понял формат внутри и проигнорировал.
3. `.icon`-папка как top-level folder reference (`type: folder` в
   XcodeGen) рядом с `Assets.xcassets`, по инструкции из независимых
   отчётов в интернете про Icon Composer — тоже пустая иконка: файл
   просто копируется в бандл через `CpResource`, `actool` его вообще
   не касается.

Статический поиск (`strings`/`grep` по всему `Xcode.app`, включая
бинарники) не нашёл никакой текстовой UTI-декларации для `.icon` —
регистрация типа не текстовая строка, найти её так нельзя.

**Настоящая причина** нашлась только через ручной эксперимент в
реальном Xcode 26.6 (Hackintosh-виртуалка без Metal — рендеринг не
нужен для этого шага, нужна только IDE): создан пустой проект, `.icon`
файл перетащен в Project Navigator **на тот же уровень, что и
Assets.xcassets** (не внутрь неё), затем `project.pbxproj` изучен
напрямую через `cat`.

Ключевое отличие: современный Xcode (16+, и это по умолчанию у любого
нового проекта в Xcode 26) не создаёт `PBXFileReference` на каждый файл
вообще. Вместо этого — **`PBXFileSystemSynchronizedRootGroup`**
(«synced folders» / «buildable folders»): Xcode просто ссылается на
папку целиком, а какие в ней source-файлы, какие ресурсы, какие
ассет-каталоги — сканирует **при сборке**, а не хранит в pbxproj. Для
`.icon`-файла внутри такой папки никакого `lastKnownFileType` не
существует и не нужно — Xcode находит его по совпадению имени файла
(без расширения) с настройкой сборки `ASSETCATALOG_COMPILER_APPICON_NAME`.
Подтверждено дампом реального `project.pbxproj`: после добавления
`.icon`-файла и выбора его в General → App Icon единственное отличие в
файле — это `ASSETCATALOG_COMPILER_APPICON_NAME = "<имя файла>";`,
больше ничего.

XcodeGen поддерживает синхронизированные папки через
`type: syncedFolder` (доступно начиная с `projectFormat: xcode16_0` —
это дефолт). Рабочая конфигурация (см. `project.yml`):

```yaml
targets:
  Luma:
    sources:
      - path: Luma
        excludes:
          - "Resources/AppIcon.icon/**"
      - path: Luma/Resources/AppIcon.icon
        type: syncedFolder
    settings:
      base:
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
```

Папка должна называться ровно `AppIcon.icon` (совпадать с именем в
`ASSETCATALOG_COMPILER_APPICON_NAME`, без расширения). Старая попытка
`type: folder` (без `syncedFolder`) даёт `lastKnownFileType = folder;`
в pbxproj — именно это и есть настоящая причина, почему `actool` не
подхватывал файл; дело было не в содержимом `icon.json` и не в
XcodeGen-версии, а именно в модели файловых ссылок.

Также по пути выяснилось: top-level ключ `resources:` в `project.yml`
у XcodeGen **не задокументирован и ничего не делает** (проверено по
`ProjectSpec.md`) — все файлы `Luma/Resources` и так подхватывались
через основной `sources: - path: Luma`. Убран как мёртвый конфиг.

### Тёмный/светлый режим — вручную, не автоматически

Система **не** инвертирует/перекрашивает плоский PNG сама. Если задать
фон и глиф одной картинкой без прозрачности — в тёмном режиме будет
тот же светлый фон. Правильно: фон — это `fill`/`fill-specializations`
в JSON (цвет, не картинка) с явным вариантом на `appearance: dark`; глиф
— прозрачный PNG + `fill-specializations` слоя с явной перекраской под
тёмный режим (см. шаг 3 выше). Оба варианта задаются руками, каждый
отдельно.

## Тесты

`LumaTests` — XCTest, таргетируется на `Luma` через `@testable import Luma`.
На Этапе 1 тесты проверяют только моковые данные и `AppState` (см.
`LumaTests/LumaTests.swift`). Запускаются в CI (`tests.yml`, а также как шаг
внутри `build.yml`) на симуляторе `iPhone 17` (см. `KNOWN_ISSUES.md` про
подверженность имени симулятора изменениям линейки).
