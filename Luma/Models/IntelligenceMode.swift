import Foundation

enum IntelligenceMode: String, CaseIterable, Identifiable, Hashable {
    case auto
    case fast
    case standard
    case high

    var id: String { rawValue }

    var title: String {
        switch self {
        case .auto: return "Авто"
        case .fast: return "Быстрый"
        case .standard: return "Средний"
        case .high: return "Высокий"
        }
    }

    var systemImage: String {
        switch self {
        case .auto: return "wand.and.sparkles"
        case .fast: return "bolt.fill"
        case .standard: return "circle.grid.2x2.fill"
        case .high: return "square.stack.3d.up.fill"
        }
    }

    var shortDescription: String {
        switch self {
        case .auto: return "Модель сама выбирает подходящий режим"
        case .fast: return "Минимальная задержка, 1–2 действия"
        case .standard: return "Краткий план и несколько инструментов"
        case .high: return "Многошаговый план и перепроверка результата"
        }
    }

    var detailPoints: [String] {
        switch self {
        case .auto:
            return [
                "Оценивает сложность запроса",
                "Повышает режим при ошибке или низкой уверенности",
                "Повышает режим для кода и файлов"
            ]
        case .fast:
            return [
                "Без отдельного планирования",
                "1–2 действия",
                "Короткий ответ"
            ]
        case .standard:
            return [
                "Краткий план перед действиями",
                "Несколько инструментов",
                "Одна повторная попытка при ошибке"
            ]
        case .high:
            return [
                "Многошаговый план",
                "Больше контекста и инструментов",
                "Перепланирование при необходимости",
                "Подходит для сложного кода и файлов"
            ]
        }
    }
}
