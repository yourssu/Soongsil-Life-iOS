import Foundation

final class TuitionRepository: TuitionRepositoryProtocol {
    private let service: TuitionServiceProtocol

    init(service: TuitionServiceProtocol) {
        self.service = service
    }

    func fetchTuitionRecords() async throws -> [TuitionRecord] {
        try await service.fetchTuitionRecords()
            .sorted { lhs, rhs in
                if lhs.year.academicYear != rhs.year.academicYear {
                    return lhs.year.academicYear > rhs.year.academicYear
                }

                if lhs.semester.sortOrder != rhs.semester.sortOrder {
                    return lhs.semester.sortOrder > rhs.semester.sortOrder
                }

                return lhs.registrationDate > rhs.registrationDate
            }
    }

    func fetchScholarshipRecords() async throws -> [ScholarshipRecord] {
        try await service.fetchScholarshipRecords()
            .sorted { lhs, rhs in
                if lhs.year.academicYear != rhs.year.academicYear {
                    return lhs.year.academicYear > rhs.year.academicYear
                }

                if lhs.semester.sortOrder != rhs.semester.sortOrder {
                    return lhs.semester.sortOrder > rhs.semester.sortOrder
                }

                return lhs.processDate > rhs.processDate
            }
    }
}

private extension String {
    var academicYear: Int {
        Int(filter(\.isNumber)) ?? 0
    }
}
