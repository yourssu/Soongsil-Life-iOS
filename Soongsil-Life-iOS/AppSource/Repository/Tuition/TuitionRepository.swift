import Foundation

final class TuitionRepository: TuitionRepositoryProtocol {
    private let service: TuitionServiceProtocol 

    init(service: TuitionServiceProtocol) {
        self.service = service
    }

    func fetchTuitionRecords() async throws -> [TuitionRecord] {
        try await service.fetchTuitionRecords()
        // 등록금 최신순 정렬
            .sorted { lhs, rhs in
                lhs.sortKey > rhs.sortKey
            }
    }

    func fetchScholarshipRecords() async throws -> [ScholarshipRecord] {
        try await service.fetchScholarshipRecords()
    }
}

private extension TuitionRecord {
    var sortKey: String {
        "\(year.digitsOnly)-\(semesterSortValue)-\(registrationDate)"
    }

    var semesterSortValue: String {
        if semester.contains("겨울") {
            return "4"
        }
        if semester.contains("2") || semester.contains("후") {
            return "3"
        }
        if semester.contains("여름") {
            return "2"
        }
        if semester.contains("1") || semester.contains("전") {
            return "1"
        }
        return "0"
    }
}

private extension String {
    var digitsOnly: String {
        filter(\.isNumber)
    }
}
