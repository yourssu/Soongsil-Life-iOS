import Foundation

protocol TimetableServiceProtocol: Sendable {
    func fetchTimetable() async throws -> TimetableSchedule?
}
