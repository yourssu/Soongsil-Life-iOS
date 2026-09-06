import Foundation

@MainActor
final class GradeRepository: GradeRepositoryProtocol {
    private struct CourseKey: Hashable {
        let year: String
        let semester: AcademicSemester
    }

    private struct Request<Value> {
        let id: UUID
        let writeContext: GradeCacheWriteContext?
        let task: Task<Value, Error>
    }

    private let service: GradeServiceProtocol
    private let cacheStore: GradeCacheStoreProtocol
    private let refreshInterval: TimeInterval
    private let now: @Sendable () -> Date
    private let onSummaryChanged: (() -> Void)?
    private var semesterRequest: Request<[SemesterGrade]>?
    private var courseRequests: [CourseKey: Request<[CourseGrade]>] = [:]

    init(
        service: GradeServiceProtocol,
        cacheStore: GradeCacheStoreProtocol? = nil,
        refreshInterval: TimeInterval = 24 * 60 * 60,
        now: @escaping @Sendable () -> Date = { Date() },
        onSummaryChanged: (() -> Void)? = nil
    ) {
        self.service = service
        self.cacheStore = cacheStore ?? InMemoryGradeCacheStore()
        self.refreshInterval = refreshInterval
        self.now = now
        self.onSummaryChanged = onSummaryChanged
    }

    func cachedSemesters() -> [SemesterGrade]? {
        cacheStore.cachedSemesters()?.value
    }

    func fetchSemesters(forceRefresh: Bool) async throws -> [SemesterGrade] {
        if !forceRefresh,
           let cached = cacheStore.cachedSemesters(),
           isFresh(cached.savedAt) {
            return cached.value
        }

        let writeContext = cacheStore.makeWriteContext()
        if let request = semesterRequest,
           let writeContext,
           request.writeContext == writeContext {
            return try await request.task.value
        }

        let previousSemesters = cacheStore.cachedSemesters()?.value
        let request = Request(
            id: UUID(),
            writeContext: writeContext,
            task: Task { try await service.fetchSemesters() }
        )
        semesterRequest = request

        do {
            let semesters = try await request.task.value
            if semesterRequest?.id == request.id {
                semesterRequest = nil
            }
            guard let writeContext,
                  let savedSemesters = cacheStore.saveSemesters(
                      semesters,
                      savedAt: now(),
                      using: writeContext
                  )
            else {
                return semesters
            }
            if let previousSemesters,
               previousSemesters != savedSemesters {
                onSummaryChanged?()
            }
            return savedSemesters
        } catch {
            if semesterRequest?.id == request.id {
                semesterRequest = nil
            }
            throw error
        }
    }

    func cachedCourses(
        year: String,
        semester: AcademicSemester
    ) -> [CourseGrade]? {
        cacheStore.cachedCourses(year: year, semester: semester)?.value
    }

    func fetchCourses(
        year: String,
        semester: AcademicSemester,
        forceRefresh: Bool
    ) async throws -> [CourseGrade] {
        if !forceRefresh,
           let cached = cacheStore.cachedCourses(year: year, semester: semester),
           shouldUseCachedCourses(
               cached,
               year: year,
               semester: semester
           ) {
            return cached.value
        }

        let key = CourseKey(year: year, semester: semester)
        let writeContext = cacheStore.makeWriteContext()
        if let request = courseRequests[key],
           let writeContext,
           request.writeContext == writeContext {
            return try await request.task.value
        }

        let request = Request(
            id: UUID(),
            writeContext: writeContext,
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
            guard let writeContext else { return courses }
            return cacheStore.saveCourses(
                courses,
                year: year,
                semester: semester,
                savedAt: now(),
                using: writeContext
            ) ?? courses
        } catch {
            if courseRequests[key]?.id == request.id {
                courseRequests[key] = nil
            }
            throw error
        }
    }

    private func shouldUseCachedCourses(
        _ cached: GradeCacheValue<[CourseGrade]>,
        year: String,
        semester: AcademicSemester
    ) -> Bool {
        guard let latestSemester = cacheStore.cachedSemesters()?.value.last else {
            return isFresh(cached.savedAt)
        }
        let requestedID = "\(year)-\(semester.rawValue)"
        return requestedID != latestSemester.id || isFresh(cached.savedAt)
    }

    private func isFresh(_ savedAt: Date) -> Bool {
        let age = now().timeIntervalSince(savedAt)
        return age >= 0 && age < refreshInterval
    }
}
