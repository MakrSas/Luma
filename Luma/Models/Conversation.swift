import Foundation

struct Conversation: Identifiable, Hashable {
    let id: UUID
    var title: String
    var summary: String
    var messages: [ChatMessage]
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
    var isTemporary: Bool
    var heroImageName: String?
    var accentTag: String?

    static func newEmpty(temporary: Bool) -> Conversation {
        Conversation(
            id: UUID(),
            title: "Новый диалог",
            summary: "",
            messages: [],
            createdAt: .now,
            updatedAt: .now,
            isPinned: false,
            isTemporary: temporary,
            heroImageName: nil,
            accentTag: nil
        )
    }
}

struct ChatMessage: Identifiable, Hashable {
    enum Role: Hashable {
        case user
        case assistant
        case toolAction
        case richCard
        case widgets
    }

    let id: UUID
    var role: Role
    var text: String
    var createdAt: Date
    var isStreaming: Bool = false
    var toolAction: ToolActionCard?
    var richCard: RichAnswerCard?
    var widgets: [AnswerWidget]?
}

struct ToolActionCard: Identifiable, Hashable {
    let id: UUID
    var toolName: String
    var displayTitle: String
    var detail: String
    var riskLevel: RiskLevel
    var status: ActionStatus

    enum ActionStatus: Hashable {
        case pending
        case awaitingConfirmation
        case running
        case succeeded
        case failed
        case cancelled
    }
}

extension Conversation {
    static let mockList: [Conversation] = [
        Conversation(
            id: UUID(),
            title: "Отпуск в Мехико",
            summary: "Парк Чапультепек, музеи и маршрут на 3 дня",
            messages: ChatMessage.mockThreadTravel,
            createdAt: .now.addingTimeInterval(-86_400 * 2),
            updatedAt: .now.addingTimeInterval(-3_600),
            isPinned: true,
            isTemporary: false,
            heroImageName: "photo.fill",
            accentTag: "Путешествия"
        ),
        Conversation(
            id: UUID(),
            title: "Напоминания на неделю",
            summary: "Тренировки, встреча с врачом, продление паспорта",
            messages: ChatMessage.mockThreadReminders,
            createdAt: .now.addingTimeInterval(-86_400),
            updatedAt: .now.addingTimeInterval(-7_200),
            isPinned: false,
            isTemporary: false,
            heroImageName: nil,
            accentTag: "Задачи"
        ),
        Conversation(
            id: UUID(),
            title: "Рефакторинг сетевого слоя",
            summary: "Обсуждение архитектуры и разбиение на модули",
            messages: ChatMessage.mockThreadCode,
            createdAt: .now.addingTimeInterval(-86_400 * 5),
            updatedAt: .now.addingTimeInterval(-86_400 * 4),
            isPinned: false,
            isTemporary: false,
            heroImageName: "chevron.left.forwardslash.chevron.right",
            accentTag: "Код"
        ),
        Conversation(
            id: UUID(),
            title: "Идеи подарков",
            summary: "Дню рождения мамы через две недели",
            messages: [],
            createdAt: .now.addingTimeInterval(-86_400 * 9),
            updatedAt: .now.addingTimeInterval(-86_400 * 8),
            isPinned: false,
            isTemporary: false,
            heroImageName: nil,
            accentTag: nil
        ),
        Conversation(
            id: UUID(),
            title: "Планирование бюджета",
            summary: "Расходы на июль и цели по накоплениям",
            messages: [],
            createdAt: .now.addingTimeInterval(-86_400 * 14),
            updatedAt: .now.addingTimeInterval(-86_400 * 13),
            isPinned: false,
            isTemporary: false,
            heroImageName: "chart.pie.fill",
            accentTag: "Финансы"
        )
    ]
}

extension ChatMessage {
    static let mockThreadTravel: [ChatMessage] = [
        ChatMessage(id: UUID(), role: .user, text: "Что посмотреть в парке Чапультепек?", createdAt: .now.addingTimeInterval(-4000)),
        ChatMessage(id: UUID(), role: .assistant, text: "Парк разделён на четыре зоны и считается одним из крупнейших городских парков мира. Стоит посмотреть замок Чапультепек, Национальный музей антропологии и зоопарк.", createdAt: .now.addingTimeInterval(-3900)),
        ChatMessage(
            id: UUID(),
            role: .richCard,
            text: "",
            createdAt: .now.addingTimeInterval(-3850),
            richCard: RichAnswerCard(
                id: UUID(),
                symbolName: "building.columns.fill",
                title: "Национальный музей антропологии",
                subtitle: "Крупнейший музей Мексики, посвящённый доколумбовым культурам. Открыт ежедневно, кроме понедельника.",
                sourceLabel: "wikipedia.org"
            )
        ),
        ChatMessage(id: UUID(), role: .user, text: "Добавь напоминание сходить в музей антропологии в субботу в 11:00", createdAt: .now.addingTimeInterval(-3800)),
        ChatMessage(
            id: UUID(),
            role: .toolAction,
            text: "",
            createdAt: .now.addingTimeInterval(-3790),
            toolAction: ToolActionCard(
                id: UUID(),
                toolName: "create_reminder",
                displayTitle: "Напоминание создано",
                detail: "«Музей антропологии» — суббота, 11:00",
                riskLevel: .low,
                status: .succeeded
            )
        )
    ]

    static let mockThreadReminders: [ChatMessage] = [
        ChatMessage(id: UUID(), role: .user, text: "Покажи мои напоминания на эту неделю", createdAt: .now.addingTimeInterval(-9000)),
        ChatMessage(id: UUID(), role: .assistant, text: "У вас 3 активных напоминания: тренировка во вторник, встреча с врачом в четверг и продление паспорта до пятницы.", createdAt: .now.addingTimeInterval(-8950))
    ]

    static let mockThreadCode: [ChatMessage] = [
        ChatMessage(id: UUID(), role: .user, text: "Как лучше разделить сетевой слой на модули?", createdAt: .now.addingTimeInterval(-400_000)),
        ChatMessage(id: UUID(), role: .assistant, text: "Разумно выделить отдельный пакет для транспортного слоя, отдельный — для моделей запросов/ответов, и отдельный — для авторизации и повторных попыток.", createdAt: .now.addingTimeInterval(-399_950))
    ]
}
