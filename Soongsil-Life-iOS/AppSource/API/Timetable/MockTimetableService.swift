import Foundation

final class MockTimetableService: TimetableServiceProtocol, @unchecked Sendable {
    private let year: String
    private let semester: String
    private let cells: [TimetableCellData]
    private let delay: Duration
    private let error: Error?

    init(
        year: String = "2024학년도",
        semester: String = "2학기",
        cells: [TimetableCellData] = MockTimetableFixtures.cells,
        delay: Duration = .milliseconds(150),
        error: Error? = nil
    ) {
        self.year = year
        self.semester = semester
        self.cells = cells
        self.delay = delay
        self.error = error
    }

    func fetchAvailablePeriods() async throws -> [TimetablePeriod] {
        if let error {
            throw error
        }
        return [
            TimetablePeriod(year: "2024", semester: .second),
            TimetablePeriod(year: "2024", semester: .first),
            TimetablePeriod(year: "2023", semester: .second)
        ]
    }

    func fetchTimetable(
        for period: TimetablePeriod?
    ) async throws -> TimetableSchedule? {
        try await MockDelay.wait(delay)
        if let error {
            throw error
        }
        return TimetableSchedule(
            data: TimetableData(
                year: period.map { "\($0.year)학년도" } ?? year,
                semester: period?.semester.localizedName ?? semester,
                items: cells
            )
        )
    }
}

enum MockTimetableFixtures {
    static let cells: [TimetableCellData] = [
        cell(.monday, 2, "09:00", "09:50", "운영체제", "김영진", "정보과학관 21304"),
        cell(.monday, 3, "10:30", "11:20", "데이터베이스응용", "이상호", "정보과학관 21303"),
        cell(.monday, 4, "11:30", "11:45", "데이터베이스응용", "이상호", "정보과학관 21303"),
        cell(.monday, 6, "13:00", "13:50", "비전채플", "", "한경직기념관"),
        cell(.monday, 7, "14:00", "14:50", "캡스톤디자인종합프로젝트1", "박영택", "정보과학관 21304"),
        cell(.monday, 8, "15:00", "15:50", "캡스톤디자인종합프로젝트1", "박영택", "정보과학관 21304"),
        cell(.tuesday, 2, "09:00", "09:50", "운영체제", "김영진", "정보과학관 21304"),
        cell(.tuesday, 3, "10:30", "11:20", "네트워크보안", "최종현", "정보과학관 21305"),
        cell(.tuesday, 9, "16:00", "16:50", "캡스톤디자인종합프로젝트1", "박영택", "미래관 20402"),
        cell(.tuesday, 10, "17:00", "17:50", "캡스톤디자인종합프로젝트1", "박영택", "미래관 20402"),
        cell(.wednesday, 3, "10:30", "11:20", "데이터베이스응용", "이상호", "정보과학관 21303"),
        cell(.wednesday, 5, "12:00", "12:50", "소프트웨어분석및설계", "정성태", "정보과학관 21304"),
        cell(.friday, 3, "10:30", "11:20", "UI/UX설계및실습", "한혁수", "정보과학관 21305"),
        cell(.friday, 5, "12:00", "12:50", "소프트웨어분석및설계", "정성태", "정보과학관 21304")
    ]

    static let earlyStartCells: [TimetableCellData] = [
        cell(.monday, 1, "08:00", "08:50", "운영체제", "김영진", "정보과학관 21304")
    ] + cells

    private static func cell(
        _ weekday: TimetableWeekday,
        _ period: Int,
        _ start: String,
        _ end: String,
        _ subject: String,
        _ professor: String,
        _ classroom: String
    ) -> TimetableCellData {
        let periodTime = "(\(start)-\(end))"
        return TimetableCellData(
            dayOfWeek: serverName(weekday),
            period: "\(period) 교시",
            periodTime: periodTime,
            subject: subject,
            professor: professor,
            time: periodTime,
            classroom: classroom
        )
    }

    private static func serverName(_ weekday: TimetableWeekday) -> String {
        switch weekday {
        case .monday: "MONDAY"
        case .tuesday: "TUESDAY"
        case .wednesday: "WEDNESDAY"
        case .thursday: "THURSDAY"
        case .friday: "FRIDAY"
        case .saturday: "SATURDAY"
        case .sunday: "SUNDAY"
        }
    }
}
