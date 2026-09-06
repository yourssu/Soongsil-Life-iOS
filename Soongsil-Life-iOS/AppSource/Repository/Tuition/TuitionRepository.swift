import Foundation

final class TuitionRepository: TuitionRepositoryProtocol {
    private let service: TuitionServiceProtocol
    private let cacheStore: TuitionCacheStoreProtocol

    init(
        service: TuitionServiceProtocol,
        cacheStore: TuitionCacheStoreProtocol = FileTuitionCacheStore()
    ) {
        self.service = service
        self.cacheStore = cacheStore
    }

    func cachedTuitionRecords() -> CachedTuitionRecords? {
        cacheStore.loadTuitionRecords()
    }

    func cachedScholarshipRecords() -> CachedScholarshipRecords? {
        cacheStore.loadScholarshipRecords()
    }

    func fetchTuitionRecords() async throws -> [TuitionRecord] {
        let cacheContext = cacheStore.makeWriteContext()
        let records = try await service.fetchTuitionRecords()
            .sorted { lhs, rhs in
                if lhs.year.academicYear != rhs.year.academicYear {
                    return lhs.year.academicYear > rhs.year.academicYear
                }

                if lhs.semester.sortOrder != rhs.semester.sortOrder {
                    return lhs.semester.sortOrder > rhs.semester.sortOrder
                }

                return lhs.registrationDate > rhs.registrationDate
            }
        if let cacheContext {
            cacheStore.saveTuitionRecords(records, using: cacheContext)
        }
        return records
    }

    func fetchScholarshipRecords() async throws -> [ScholarshipRecord] {
        let cacheContext = cacheStore.makeWriteContext()
        let records = try await service.fetchScholarshipRecords()
            .sorted { lhs, rhs in
                if lhs.year.academicYear != rhs.year.academicYear {
                    return lhs.year.academicYear > rhs.year.academicYear
                }

                if lhs.semester.sortOrder != rhs.semester.sortOrder {
                    return lhs.semester.sortOrder > rhs.semester.sortOrder
                }

                return lhs.processDate > rhs.processDate
            }
        if let cacheContext {
            cacheStore.saveScholarshipRecords(records, using: cacheContext)
        }
        return records
    }
}

private extension String {
    var academicYear: Int {
        Int(filter(\.isNumber)) ?? 0
    }
}
