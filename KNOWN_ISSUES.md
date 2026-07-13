# KNOWN_ISSUES.md

## Риски CI

- **SDK-зависимость Liquid Glass**: `glassEffect`, `GlassEffectContainer` и
  `.buttonStyle(.glass/.glassProminent)` объявлены в SDK iOS 26. Все вызовы
  обёрнуты в `#available(iOS 26.0, *)` с fallback на `Material`
  (`Luma/DesignSystem/LumaGlass.swift`), но **сам код должен компилироваться**,
  а значит Xcode на раннере GitHub Actions обязан включать iOS 26 SDK. Workflow
  `build.yml` выбирает самый новый установленный Xcode (`sort -V | tail -1`) —
  если на раннере окажется только более старый Xcode без iOS 26 SDK, сборка
  упадёт на строках с `.glassEffect`/`.glass`. В этом случае нужно либо
  дождаться обновления образа `macos-15`, либо временно закрепить более новый
  `macos-*` раннер в workflow.
- **`iPhone 15` симулятор для тестов**: имя симулятора в `-destination` должно
  существовать в образе раннера. Если Apple переименует/уберёт конкретную
  модель из образа, `xcodebuild test` в `build.yml`/`tests.yml` упадёт на этапе
  выбора destination — тогда нужно поменять имя на актуальное (`xcrun simctl
  list devices`).

## Установка unsigned IPA

`build.yml` и `release-unsigned.yml` собирают **неподписанный** IPA
(`CODE_SIGNING_ALLOWED=NO`). Обычный iPhone не установит такой файл напрямую —
нужен пересборщик подписи на стороне пользователя (например AltStore,
Sideloadly или аналог с собственным Apple ID). Это ограничение процесса
сборки без Mac и без Apple Developer Program, а не баг Luma.

## Дизайн / UI

- `ModelDetailView` использует принудительное разворачивание `model!` в
  нескольких computed properties, полагаясь на то, что экран не рендерится
  при `model == nil` (заглушка `ContentUnavailableView` в `body`). Это
  приемлемо для Этапа 1 на моковых данных, но при переходе на реальный
  каталог моделей (Этап 5) стоит заменить на безопасный `guard let`.
- `HistoryView` сортирует по закреплению нестрогим компаратором
  (`{ $0.isPinned && !$1.isPinned }`), что не является строгим слабым
  порядком в строгом смысле, но при небольшом количестве диалогов на моках
  ведёт себя предсказуемо. Пересмотреть при реальных данных большого объёма.

## Не проблема, а осознанное ограничение

- Экран загрузки модели (`ModelDownloadView`) анимирует прогресс локальным
  `Timer`, реальной сети/файловой системы нет — это ожидаемо для Этапа 1.
- `ChatView` симулирует потоковую генерацию посимвольно через `Task.sleep`,
  без реального `LocalInferenceEngine` — тоже ожидаемо для Этапа 1.
