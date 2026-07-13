import Foundation

enum PermissionState: String, CaseIterable, Identifiable, Hashable {
    case denied
    case ask
    case allowed

    var id: String { rawValue }

    var label: String {
        switch self {
        case .denied: return "Запрещено"
        case .ask: return "Спрашивать"
        case .allowed: return "Разрешено"
        }
    }

    var systemImage: String {
        switch self {
        case .denied: return "xmark.circle.fill"
        case .ask: return "questionmark.circle.fill"
        case .allowed: return "checkmark.circle.fill"
        }
    }
}

struct ToolPermission: Identifiable, Hashable {
    let id: String
    var toolName: String
    var displayName: String
    var toolDescription: String
    var riskLevel: RiskLevel
    var state: PermissionState
    var requiresSystemPermission: String?
}

extension ToolPermission {
    static let mockList: [ToolPermission] = [
        ToolPermission(id: "create_reminder", toolName: "create_reminder", displayName: "Создание напоминаний", toolDescription: "Создаёт новое напоминание в приложении «Напоминания».", riskLevel: .low, state: .allowed, requiresSystemPermission: "Напоминания"),
        ToolPermission(id: "list_reminders", toolName: "list_reminders", displayName: "Просмотр напоминаний", toolDescription: "Читает список существующих напоминаний.", riskLevel: .low, state: .allowed, requiresSystemPermission: "Напоминания"),
        ToolPermission(id: "complete_reminder", toolName: "complete_reminder", displayName: "Завершение напоминаний", toolDescription: "Отмечает напоминание выполненным.", riskLevel: .low, state: .ask, requiresSystemPermission: "Напоминания"),
        ToolPermission(id: "create_calendar_event", toolName: "create_calendar_event", displayName: "Создание событий календаря", toolDescription: "Добавляет новое событие в календарь.", riskLevel: .medium, state: .ask, requiresSystemPermission: "Календарь"),
        ToolPermission(id: "update_calendar_event", toolName: "update_calendar_event", displayName: "Изменение событий календаря", toolDescription: "Изменяет уже существующее событие.", riskLevel: .medium, state: .ask, requiresSystemPermission: "Календарь"),
        ToolPermission(id: "list_calendar_events", toolName: "list_calendar_events", displayName: "Просмотр календаря", toolDescription: "Читает события календаря за период.", riskLevel: .low, state: .allowed, requiresSystemPermission: "Календарь"),
        ToolPermission(id: "find_free_time", toolName: "find_free_time", displayName: "Поиск свободного времени", toolDescription: "Анализирует календарь и предлагает свободные слоты.", riskLevel: .low, state: .allowed, requiresSystemPermission: "Календарь"),
        ToolPermission(id: "search_contacts", toolName: "search_contacts", displayName: "Поиск контактов", toolDescription: "Ищет контакт по имени или другим данным.", riskLevel: .medium, state: .ask, requiresSystemPermission: "Контакты"),
        ToolPermission(id: "open_url", toolName: "open_url", displayName: "Открытие ссылок", toolDescription: "Открывает URL в браузере по умолчанию.", riskLevel: .medium, state: .ask, requiresSystemPermission: nil),
        ToolPermission(id: "open_supported_app", toolName: "open_supported_app", displayName: "Открытие приложений", toolDescription: "Открывает поддерживаемое приложение через системную ссылку.", riskLevel: .low, state: .allowed, requiresSystemPermission: nil),
        ToolPermission(id: "read_clipboard", toolName: "read_clipboard", displayName: "Чтение буфера обмена", toolDescription: "Читает текущее содержимое буфера обмена.", riskLevel: .medium, state: .ask, requiresSystemPermission: nil),
        ToolPermission(id: "write_clipboard", toolName: "write_clipboard", displayName: "Запись в буфер обмена", toolDescription: "Копирует текст в буфер обмена.", riskLevel: .low, state: .allowed, requiresSystemPermission: nil),
        ToolPermission(id: "select_file", toolName: "select_file", displayName: "Выбор файла", toolDescription: "Открывает системный выбор файла.", riskLevel: .low, state: .allowed, requiresSystemPermission: nil),
        ToolPermission(id: "read_authorized_file", toolName: "read_authorized_file", displayName: "Чтение выбранного файла", toolDescription: "Читает содержимое ранее выбранного файла.", riskLevel: .medium, state: .ask, requiresSystemPermission: nil),
        ToolPermission(id: "search_authorized_photos", toolName: "search_authorized_photos", displayName: "Поиск по фото", toolDescription: "Ищет фотографии по описанию среди разрешённых альбомов.", riskLevel: .medium, state: .denied, requiresSystemPermission: "Фото"),
        ToolPermission(id: "create_local_notification", toolName: "create_local_notification", displayName: "Локальные уведомления", toolDescription: "Создаёт уведомление о статусе выполнения задачи.", riskLevel: .low, state: .allowed, requiresSystemPermission: "Уведомления"),
        ToolPermission(id: "get_device_status", toolName: "get_device_status", displayName: "Статус устройства", toolDescription: "Читает заряд батареи, память и другие системные показатели.", riskLevel: .low, state: .allowed, requiresSystemPermission: nil),
        ToolPermission(id: "run_internal_workflow", toolName: "run_internal_workflow", displayName: "Внутренние сценарии", toolDescription: "Запускает сохранённую последовательность действий.", riskLevel: .medium, state: .ask, requiresSystemPermission: nil),
        ToolPermission(id: "search_agent_memory", toolName: "search_agent_memory", displayName: "Поиск в памяти", toolDescription: "Ищет сведения в долговременной памяти агента.", riskLevel: .low, state: .allowed, requiresSystemPermission: nil),
        ToolPermission(id: "propose_memory", toolName: "propose_memory", displayName: "Предложение сохранить в память", toolDescription: "Предлагает сохранить новую запись в долговременную память.", riskLevel: .medium, state: .ask, requiresSystemPermission: nil),
        ToolPermission(id: "update_memory", toolName: "update_memory", displayName: "Изменение памяти", toolDescription: "Изменяет существующую запись памяти.", riskLevel: .medium, state: .ask, requiresSystemPermission: nil),
        ToolPermission(id: "forget_memory", toolName: "forget_memory", displayName: "Удаление из памяти", toolDescription: "Удаляет запись из долговременной памяти.", riskLevel: .high, state: .ask, requiresSystemPermission: nil)
    ]
}
