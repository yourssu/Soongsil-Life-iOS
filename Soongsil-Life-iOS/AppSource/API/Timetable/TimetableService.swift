import Foundation
import LmsApi

final class TimetableService: TimetableServiceProtocol, @unchecked Sendable {
    private let api = LmsApi.shared

    func fetchTimetable() async throws -> TimetableSchedule? {
        try await withCheckedThrowingContinuation { continuation in
            api.getTimetable { result in
                guard result.success else {
                    continuation.resume(
                        throwing: LMSServiceError.message(
                            result.errorMessage ?? "시간표를 불러오지 못했습니다."
                        )
                    )
                    return
                }

                guard let timetable = result.timetable else {
                    continuation.resume(returning: nil)
                    return
                }

                let data = TimetableData(
                    year: timetable.year,
                    semester: timetable.semester,
                    items: timetable.items.map {
                        TimetableCellData(
                            dayOfWeek: $0.dayOfWeek.name,
                            period: $0.period,
                            periodTime: $0.periodTime,
                            subject: $0.subject,
                            professor: $0.professor,
                            time: $0.time,
                            classroom: $0.classroom
                        )
                    }
                )
                continuation.resume(returning: TimetableSchedule(data: data))
            }
        }
    }
}

enum TimetableDataSource {
    static func makeService() -> TimetableServiceProtocol {
#if targetEnvironment(simulator)
        MockTimetableService()
#else
        TimetableService()
#endif
    }
}
