import Foundation

/// 시간표 탭 단독 테스트용 서비스.
/// 셀 형식은 `LmsApi` 의 `TimetableCell` 과 동일하게 맞춰 실제 응답과 같은 경로로 파싱됩니다.
final class MockTimetableService: TimetableServiceProtocol, @unchecked Sendable {
    private let year: String
    private let semester: String
    private let cells: [TimetableCellData]
    private let delayNanoseconds: UInt64
    private let error: Error?

    init(
        year: String = "2024학년도",
        semester: String = "2학기",
        cells: [TimetableCellData] = MockTimetableFixtures.cells,
        delayNanoseconds: UInt64 = 400_000_000,
        error: Error? = nil
    ) {
        self.year = year
        self.semester = semester
        self.cells = cells
        self.delayNanoseconds = delayNanoseconds
        self.error = error
    }

    func fetchTimetable() async throws -> TimetableSchedule? {
        if delayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        if let error { throw error }
        guard !cells.isEmpty else { return nil }
        return TimetableSchedule(
            data: TimetableData(year: year, semester: semester, items: cells)
        )
    }
}

enum MockTimetableFixtures {
    /// Figma 시안과 동일한 구성. 교시 단위로 내려오는 실제 응답 형태를 그대로 재현합니다.
    static let cells: [TimetableCellData] = [
        cell(.monday, 1, "08:00", "08:50", "운영체제", "김영진", "정보과학관 21304"),
        cell(.monday, 2, "09:00", "09:50", "운영체제", "김영진", "정보과학관 21304"),
        cell(.monday, 3, "10:30", "11:20", "데이터베이스응용", "이상호", "정보과학관 21303"),
        cell(.monday, 4, "11:30", "11:45", "데이터베이스응용", "이상호", "정보과학관 21303"),
        cell(.monday, 6, "13:00", "13:50", "비전채플", "", "한경직기념관"),
        cell(.monday, 7, "14:00", "14:50", "캡스톤디자인종합프로젝트1", "박영택", "정보과학관 21304"),
        cell(.monday, 8, "15:00", "15:50", "캡스톤디자인종합프로젝트1", "박영택", "정보과학관 21304"),

        cell(.tuesday, 1, "08:00", "08:50", "운영체제", "김영진", "정보과학관 21304"),
        cell(.tuesday, 2, "09:00", "09:50", "운영체제", "김영진", "정보과학관 21304"),
        cell(.tuesday, 3, "10:30", "11:20", "네트워크보안", "최종현", "정보과학관 21305"),
        cell(.tuesday, 9, "16:00", "16:50", "캡스톤디자인종합프로젝트1", "박영택", "미래관 20402"),
        cell(.tuesday, 10, "17:00", "17:50", "캡스톤디자인종합프로젝트1", "박영택", "미래관 20402"),

        cell(.wednesday, 1, "08:00", "08:50", "네트워크보안", "최종현", "정보과학관 21305"),
        cell(.wednesday, 3, "10:30", "11:20", "데이터베이스응용", "이상호", "정보과학관 21303"),
        cell(.wednesday, 5, "12:00", "12:50", "소프트웨어분석및설계", "정성태", "정보과학관 21304"),

        cell(.friday, 3, "10:30", "11:20", "UI/UX설계및실습", "한혁수", "정보과학관 21305"),
        cell(.friday, 5, "12:00", "12:50", "소프트웨어분석및설계", "정성태", "정보과학관 21304")
    ]

    /// 요일 문자열은 KMP `DayOfWeek` enum 이 내려주는 대문자 표기를 사용
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
