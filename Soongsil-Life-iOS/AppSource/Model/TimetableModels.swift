import Foundation

struct TimetableData: Sendable {
    let year: String
    let semester: String
    let items: [TimetableCellData]
}

struct TimetableCellData: Sendable {
    let dayOfWeek: String
    let period: String
    let periodTime: String
    let subject: String
    let professor: String
    let time: String
    let classroom: String
}

enum TimetableWeekday: Int, CaseIterable, Sendable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday

    init?(serverName: String) {
        switch serverName.uppercased() {
        case "MONDAY": self = .monday
        case "TUESDAY": self = .tuesday
        case "WEDNESDAY": self = .wednesday
        case "THURSDAY": self = .thursday
        case "FRIDAY": self = .friday
        case "SATURDAY": self = .saturday
        case "SUNDAY": self = .sunday
        default: return nil
        }
    }

    var shortName: String {
        switch self {
        case .monday: "월"
        case .tuesday: "화"
        case .wednesday: "수"
        case .thursday: "목"
        case .friday: "금"
        case .saturday: "토"
        case .sunday: "일"
        }
    }
}

struct TimetableCourseBlock: Identifiable, Sendable {
    let id: UUID
    let weekday: TimetableWeekday
    let period: Int
    let subject: String
    let professor: String
    let classroom: String
    let time: String
}

struct TimetableSchedule: Sendable {
    let title: String
    let blocks: [TimetableCourseBlock]

    init(data: TimetableData) {
        title = [data.year, data.semester]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        blocks = data.items.compactMap { item in
            guard let weekday = TimetableWeekday(serverName: item.dayOfWeek),
                  let period = Int(item.period.components(separatedBy: .decimalDigits.inverted).joined())
            else { return nil }

            return TimetableCourseBlock(
                id: UUID(),
                weekday: weekday,
                period: period,
                subject: item.subject,
                professor: item.professor,
                classroom: item.classroom,
                time: item.time.isEmpty ? item.periodTime : item.time
            )
        }
    }

    var isEmpty: Bool { blocks.isEmpty }
}
