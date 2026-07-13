import Foundation

struct ActionLogEntry: Identifiable, Hashable {
    enum Outcome: String, Hashable {
        case succeeded, failed, cancelled, confirmed, denied

        var label: String {
            switch self {
            case .succeeded: return "Выполнено"
            case .failed: return "Ошибка"
            case .cancelled: return "Отменено"
            case .confirmed: return "Подтверждено"
            case .denied: return "Отклонено"
            }
        }
    }

    let id: UUID
    var toolName: String
    var displayTitle: String
    var detail: String
    var conversationTitle: String
    var riskLevel: RiskLevel
    var outcome: Outcome
    var timestamp: Date
}

extension ActionLogEntry {
    static let mockList: [ActionLogEntry] = [
        ActionLogEntry(id: UUID(), toolName: "create_reminder", displayTitle: "Напоминание создано", detail: "«Музей антропологии» — суббота, 11:00", conversationTitle: "Отпуск в Мехико", riskLevel: .low, outcome: .succeeded, timestamp: .now.addingTimeInterval(-3_600)),
        ActionLogEntry(id: UUID(), toolName: "create_calendar_event", displayTitle: "Событие календаря создано", detail: "«Встреча с врачом» — четверг, 15:30", conversationTitle: "Напоминания на неделю", riskLevel: .medium, outcome: .confirmed, timestamp: .now.addingTimeInterval(-7_200)),
        ActionLogEntry(id: UUID(), toolName: "search_authorized_photos", displayTitle: "Поиск по фото отклонён", detail: "Нет разрешения на доступ к фото", conversationTitle: "Идеи подарков", riskLevel: .medium, outcome: .denied, timestamp: .now.addingTimeInterval(-86_400)),
        ActionLogEntry(id: UUID(), toolName: "open_url", displayTitle: "Открытие ссылки отменено", detail: "wikipedia.org/wiki/Chapultepec", conversationTitle: "Отпуск в Мехико", riskLevel: .medium, outcome: .cancelled, timestamp: .now.addingTimeInterval(-86_400 * 2)),
        ActionLogEntry(id: UUID(), toolName: "run_internal_workflow", displayTitle: "Сценарий завершился с ошибкой", detail: "Не удалось получить доступ к файлу", conversationTitle: "Рефакторинг сетевого слоя", riskLevel: .medium, outcome: .failed, timestamp: .now.addingTimeInterval(-86_400 * 5))
    ]
}
