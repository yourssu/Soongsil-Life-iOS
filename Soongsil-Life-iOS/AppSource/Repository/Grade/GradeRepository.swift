import Foundation

@MainActor
final class GradeRepository: GradeRepositoryProtocol {
    private struct CourseKey: Hashable {
        let year: String
        let semester: AcademicSemester
    }

    private struct Request<Value> {
        let id: UUID
        let task: Task<Value, Error>
    }

    private let service: GradeServiceProtocol
    private var semesterRequest: Request<[SemesterGrade]>?
    private var courseRequests: [CourseKey: Request<[CourseGrade]>] = [:]

    init(service: GradeServiceProtocol) {
        self.service = service
    }

    func fetchSemesters() async throws -> [SemesterGrade] {
        if let request = semesterRequest {
            return try await request.task.value
        }

        let request = Request(
            id: UUID(),
            task: Task { try await service.fetchSemesters() }
        )
        semesterRequest = request

        do {
            let semesters = try await request.task.value
            if semesterRequest?.id == request.id {
                semesterRequest = nil
            }
            return semesters
        } catch {
            if semesterRequest?.id == request.id {
                semesterRequest = nil
            }
            throw error
        }
    }

    func fetchCourses(
        year: String,
        semester: AcademicSemester
    ) async throws -> [CourseGrade] {
        let key = CourseKey(year: year, semester: semester)
        if let request = courseRequests[key] {
            return try await request.task.value
        }

        let request = Request(
            id: UUID(),
            task: Task {
                try await service.fetchCourses(
                    year: year,
                    semester: semester
                )
            }
        )
        courseRequests[key] = request

        do {
            let courses = try await request.task.value
            if courseRequests[key]?.id == request.id {
                courseRequests[key] = nil
            }
            return courses
        } catch {
            if courseRequests[key]?.id == request.id {
                courseRequests[key] = nil
            }
            throw error
        }
    }
}
