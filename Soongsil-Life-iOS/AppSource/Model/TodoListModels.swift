import Foundation


struct CourseTodo: Identifiable, Sendable {
    let id: String
    let subjectName: String
    let title: String
    let kind: CourseTodoKind
    let dueDate: Date?

    var daysUntilDue: Int? {
        guard let dueDate else { return nil }

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())
        let due = calendar.startOfDay(for: dueDate)
        return calendar.dateComponents([.day], from: start, to: due).day
    }
}


enum CourseTodoKind: Sendable {
    case assignment
    case video
    case quiz
    case other(String)

    init(componentType: String) {
        switch componentType.lowercased() {
        case "assignment":
            self = .assignment
        case "commons":
            self = .video
        case "quiz":
            self = .quiz
        default:
            self = .other(componentType)
        }
    }

    var localizedName: String {
        switch self {
        case .assignment: NotificationStrings.kindAssignment
        case .video: NotificationStrings.kindVideo
        case .quiz: NotificationStrings.kindQuiz
        case let .other(value): value.isEmpty ? NotificationStrings.kindOther : value
        }
    }
}
