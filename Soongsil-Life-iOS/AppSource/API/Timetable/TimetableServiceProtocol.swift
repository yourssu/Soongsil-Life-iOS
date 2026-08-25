import Foundation

protocol TimetableServiceProtocol: AnyObject, Sendable {
    func fetchAvailablePeriods() async throws -> [TimetablePeriod]

    func fetchTimetable(
        for period: TimetablePeriod?
    ) async throws -> TimetableSchedule?
}
