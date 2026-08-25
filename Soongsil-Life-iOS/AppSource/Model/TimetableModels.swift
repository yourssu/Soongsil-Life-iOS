import Foundation

struct TimetablePeriod: Hashable, Sendable {
    let year: String
    let semester: AcademicSemester

    init(year: String, semester: AcademicSemester) {
        self.year = year
        self.semester = semester
    }

    init?(apiYear: String, apiSemester: String) {
        let source = "\(apiYear) \(apiSemester)"
        let lowercaseSource = source.lowercased()
        guard !source.contains("비정규과정"),
              !lowercaseSource.contains("default term")
        else { return nil }

        let year = apiYear
            .split(whereSeparator: { !$0.isNumber })
            .first { value in
                value.count == 4 && Int(value) != nil
            }
        guard let year,
              let semester = AcademicSemester(apiValue: apiSemester)
        else { return nil }

        self.init(
            year: String(year),
            semester: semester
        )
    }
}

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

enum TimetableWeekday: Int, CaseIterable, Hashable, Sendable {
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
    let startMinutes: Int
    let endMinutes: Int
    let subject: String
    let professor: String
    let classroom: String
    let time: String
}

struct TimetableSchedule: Sendable {
    let title: String
    let period: TimetablePeriod?
    let blocks: [TimetableCourseBlock]

    init(
        data: TimetableData,
        fallbackPeriod: TimetablePeriod? = nil
    ) {
        let responseYear = data.year.trimmingCharacters(in: .whitespacesAndNewlines)
        let responseSemester = data.semester.trimmingCharacters(in: .whitespacesAndNewlines)
        let mayUseFallbackPeriod = responseYear.isEmpty && responseSemester.isEmpty
        let parsedPeriod = TimetablePeriod(
            apiYear: responseYear,
            apiSemester: responseSemester
        )
        period = parsedPeriod ?? (mayUseFallbackPeriod ? fallbackPeriod : nil)

        let titleYear = responseYear.isEmpty
            ? fallbackPeriod.map { "\($0.year)학년도" }.orEmpty
            : responseYear
        let titleSemester = responseSemester.isEmpty
            ? fallbackPeriod.map { $0.semester.localizedName }.orEmpty
            : responseSemester
        let responseTitle = [titleYear, titleSemester]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        if responseTitle.isEmpty, let period {
            title = "\(period.year)학년도 \(period.semester.localizedName)"
        } else {
            title = responseTitle
        }

        let courses = data.items.compactMap { item -> ParsedCourse? in
            guard let weekday = TimetableWeekday(serverName: item.dayOfWeek),
                  let period = Int(item.period.components(separatedBy: .decimalDigits.inverted).joined())
            else { return nil }

            let range = Self.timeRange(
                from: item.periodTime.isEmpty ? item.time : item.periodTime,
                period: period
            )
            return ParsedCourse(
                weekday: weekday,
                period: period,
                startMinutes: range.start,
                endMinutes: range.end,
                subject: item.subject,
                professor: item.professor,
                classroom: item.classroom
            )
        }

        blocks = Self.mergedBlocks(from: courses)
    }

    func inferringPeriodIfMissing(_ inferredPeriod: TimetablePeriod) -> Self {
        guard period == nil else { return self }
        return Self(
            title: title.isEmpty
                ? "\(inferredPeriod.year)학년도 \(inferredPeriod.semester.localizedName)"
                : title,
            period: inferredPeriod,
            blocks: blocks
        )
    }

    var isEmpty: Bool { blocks.isEmpty }

    var visibleWeekdays: [TimetableWeekday] {
        let weekdays = TimetableWeekday.allCases.filter { $0.rawValue <= TimetableWeekday.friday.rawValue }
        let weekend = TimetableWeekday.allCases.filter { weekday in
            weekday.rawValue > TimetableWeekday.friday.rawValue
                && blocks.contains { $0.weekday == weekday }
        }
        return weekdays + weekend
    }

    var startMinutes: Int {
        let earliest = min(
            8 * 60,
            blocks.map(\.startMinutes).min() ?? 8 * 60
        )
        return earliest / 60 * 60
    }

    var endMinutes: Int {
        let latest = max(
            18 * 60,
            blocks.map(\.endMinutes).max() ?? 18 * 60
        )
        return ((latest + 59) / 60) * 60
    }

    private struct ParsedCourse {
        let weekday: TimetableWeekday
        let period: Int
        let startMinutes: Int
        let endMinutes: Int
        let subject: String
        let professor: String
        let classroom: String

        var key: CourseKey {
            CourseKey(
                weekday: weekday,
                subject: subject,
                professor: professor,
                classroom: classroom
            )
        }
    }

    private init(
        title: String,
        period: TimetablePeriod?,
        blocks: [TimetableCourseBlock]
    ) {
        self.title = title
        self.period = period
        self.blocks = blocks
    }

    private struct CourseKey: Hashable {
        let weekday: TimetableWeekday
        let subject: String
        let professor: String
        let classroom: String
    }

    private static func mergedBlocks(
        from courses: [ParsedCourse]
    ) -> [TimetableCourseBlock] {
        Dictionary(grouping: courses, by: \.key)
            .values
            .flatMap { group -> [TimetableCourseBlock] in
                let sorted = group.sorted { $0.period < $1.period }
                guard var first = sorted.first else { return [] }

                var lastPeriod = first.period
                var endMinutes = first.endMinutes
                var result: [TimetableCourseBlock] = []

                func appendCurrent() {
                    result.append(
                        TimetableCourseBlock(
                            id: UUID(),
                            weekday: first.weekday,
                            period: first.period,
                            startMinutes: first.startMinutes,
                            endMinutes: endMinutes,
                            subject: first.subject,
                            professor: first.professor,
                            classroom: first.classroom,
                            time: "\(formattedTime(first.startMinutes))-\(formattedTime(endMinutes))"
                        )
                    )
                }

                for course in sorted.dropFirst() {
                    if course.period == lastPeriod + 1 {
                        lastPeriod = course.period
                        endMinutes = max(endMinutes, course.endMinutes)
                    } else {
                        appendCurrent()
                        first = course
                        lastPeriod = course.period
                        endMinutes = course.endMinutes
                    }
                }
                appendCurrent()
                return result
            }
            .sorted {
                if $0.weekday != $1.weekday {
                    return $0.weekday.rawValue < $1.weekday.rawValue
                }
                return $0.startMinutes < $1.startMinutes
            }
    }

    private static func timeRange(
        from value: String,
        period: Int
    ) -> (start: Int, end: Int) {
        let expression = try? NSRegularExpression(pattern: #"(\d{1,2}):(\d{2})"#)
        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        let minutes = expression?
            .matches(in: value, range: range)
            .compactMap { match -> Int? in
                guard match.numberOfRanges == 3,
                      let hourRange = Range(match.range(at: 1), in: value),
                      let minuteRange = Range(match.range(at: 2), in: value),
                      let hour = Int(value[hourRange]),
                      let minute = Int(value[minuteRange])
                else { return nil }
                return hour * 60 + minute
            } ?? []

        if minutes.count >= 2, minutes[1] > minutes[0] {
            return (minutes[0], minutes[1])
        }

        let fallbackStart = 8 * 60 + max(period - 1, 0) * 60
        return (fallbackStart, fallbackStart + 50)
    }

    private static func formattedTime(_ minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }
}

private extension Optional where Wrapped == String {
    var orEmpty: String { self ?? "" }
}
