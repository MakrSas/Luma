import Foundation

enum MemoryCategory: String, CaseIterable, Identifiable, Hashable {
    case preference
    case fact
    case project
    case task
    case decision
    case conversationSummary
    case temporary

    var id: String { rawValue }

    var label: String {
        switch self {
        case .preference: return "Предпочтение"
        case .fact: return "Постоянные сведения"
        case .project: return "Проект"
        case .task: return "Задача"
        case .decision: return "Решение"
        case .conversationSummary: return "Итог разговора"
        case .temporary: return "Временное"
        }
    }

    var systemImage: String {
        switch self {
        case .preference: return "heart.fill"
        case .fact: return "person.text.rectangle.fill"
        case .project: return "folder.fill"
        case .task: return "checklist"
        case .decision: return "checkmark.seal.fill"
        case .conversationSummary: return "text.bubble.fill"
        case .temporary: return "clock.fill"
        }
    }
}

enum MemoryScope: String, CaseIterable, Identifiable, Hashable {
    case global, project, conversation, temporary
    var id: String { rawValue }

    var label: String {
        switch self {
        case .global: return "Глобальная"
        case .project: return "Проект"
        case .conversation: return "Разговор"
        case .temporary: return "Временная"
        }
    }
}

enum MemoryMode: String, CaseIterable, Identifiable, Hashable {
    case off, askBeforeSaving, autoSave
    var id: String { rawValue }

    var label: String {
        switch self {
        case .off: return "Память выключена"
        case .askBeforeSaving: return "Спрашивать перед сохранением"
        case .autoSave: return "Сохранять автоматически"
        }
    }

    var detail: String {
        switch self {
        case .off: return "Luma не сохраняет и не использует долговременную память."
        case .askBeforeSaving: return "Перед сохранением любой новой записи агент спросит подтверждение."
        case .autoSave: return "Обычные предпочтения сохраняются автоматически. Чувствительные данные всё равно требуют подтверждения."
        }
    }
}

struct MemoryRecord: Identifiable, Hashable {
    let id: UUID
    var category: MemoryCategory
    var scope: MemoryScope
    var title: String
    var content: String
    var isPinned: Bool
    var isSensitive: Bool
    var createdAt: Date
    var updatedAt: Date
}

extension MemoryRecord {
    static let mockList: [MemoryRecord] = [
        MemoryRecord(id: UUID(), category: .preference, scope: .global, title: "Язык ответов", content: "Отвечать на русском языке, кратко и по делу.", isPinned: true, isSensitive: false, createdAt: .now.addingTimeInterval(-86_400 * 20), updatedAt: .now.addingTimeInterval(-86_400 * 20)),
        MemoryRecord(id: UUID(), category: .fact, scope: .global, title: "Часовой пояс", content: "Пользователь живёт в часовом поясе UTC+3.", isPinned: false, isSensitive: false, createdAt: .now.addingTimeInterval(-86_400 * 15), updatedAt: .now.addingTimeInterval(-86_400 * 15)),
        MemoryRecord(id: UUID(), category: .project, scope: .project, title: "Проект Luma", content: "Разрабатывает локальное ИИ-приложение для iPhone под названием Luma.", isPinned: true, isSensitive: false, createdAt: .now.addingTimeInterval(-86_400 * 3), updatedAt: .now.addingTimeInterval(-3_600)),
        MemoryRecord(id: UUID(), category: .decision, scope: .conversation, title: "Модель по умолчанию", content: "Выбрана Luma Mini 4B как модель по умолчанию для основного устройства.", isPinned: false, isSensitive: false, createdAt: .now.addingTimeInterval(-86_400), updatedAt: .now.addingTimeInterval(-86_400)),
        MemoryRecord(id: UUID(), category: .task, scope: .conversation, title: "Продление паспорта", content: "Нужно продлить паспорт до конца месяца.", isPinned: false, isSensitive: true, createdAt: .now.addingTimeInterval(-86_400 * 2), updatedAt: .now.addingTimeInterval(-86_400 * 2))
    ]
}
