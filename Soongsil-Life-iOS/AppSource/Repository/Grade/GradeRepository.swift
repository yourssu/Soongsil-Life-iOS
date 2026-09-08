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
    private var summaryRequest: Request<GradeSummary>?
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

    func cachedGradeSummary() -> GradeSummary? {
        cacheStore.cachedGradeSummary()?.value
    }

    func fetchGradeSummary(forceRefresh: Bool) async throws -> GradeSummary {
        if !forceRefresh,
           let cached = cacheStore.cachedGradeSummary(),
           cached.value.semesters.isEmpty
            || cached.value.totals?.hasCompleteCertificateSummary == true,
           isFresh(cached.savedAt) {
            return cached.value
        }

        let writeContext = cacheStore.makeWriteContext()
        if let request = summaryRequest,
           let writeContext,
           request.writeContext == writeContext {
            return try await request.task.value
        }

        let previousSummary = cacheStore.cachedGradeSummary()?.value
        let request = Request(
            id: UUID(),
            writeContext: writeContext,
            task: Task { try await service.fetchGradeSummary() }
        )
        summaryRequest = request

        do {
            let summary = try await request.task.value
            if summaryRequest?.id == request.id {
                summaryRequest = nil
            }
            guard let writeContext,
                  let savedSummary = cacheStore.saveGradeSummary(
                      summary,
                      savedAt: now(),
                      using: writeContext
                  )
            else {
                return summary
            }
            if let previousSummary,
               previousSummary != savedSummary {
                onSummaryChanged?()
            }
            return savedSummary
        } catch {
            if summaryRequest?.id == request.id {
                summaryRequest = nil
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
        guard let latestSemester = cacheStore.cachedGradeSummary()?.value.semesters.last else {
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
