import Foundation

@Observable
@MainActor
final class SemesterViewModel: BaseViewModel {
    enum Input {
        case selectSemester(SemesterGrade.ID)
        case reloadSelectedSemester
        case errorDismissed
    }

    struct Output {
        let semesters: [SemesterGrade]
        var selectedSemesterID: SemesterGrade.ID?
        var coursesBySemester: [SemesterGrade.ID: [CourseGrade]]
        var loadingSemesterIDs: Set<SemesterGrade.ID> = []
        var errorMessage: String?

        var selectedSemester: SemesterGrade? {
            semesters.first { $0.id == selectedSemesterID } ?? semesters.last
        }

        var selectedCourses: [CourseGrade] {
            guard let selectedSemesterID else { return [] }
            return coursesBySemester[selectedSemesterID] ?? []
        }

        var isLoadingSelectedSemester: Bool {
            guard let selectedSemesterID else { return false }
            return loadingSemesterIDs.contains(selectedSemesterID)
        }
    }

    private(set) var output: Output
    private let repository: GradeRepositoryProtocol

    init(
        repository: GradeRepositoryProtocol,
        semesters: [SemesterGrade],
        initialCourses: [CourseGrade] = []
    ) {
        let sortedSemesters = semesters.sorted {
            let lhs = (Int($0.year) ?? 0, $0.semester.sortOrder)
            let rhs = (Int($1.year) ?? 0, $1.semester.sortOrder)
            return lhs < rhs
        }
        let latestSemesterID = sortedSemesters.last?.id
        var initialCoursesBySemester: [SemesterGrade.ID: [CourseGrade]] = [:]
        if let latestSemesterID {
            initialCoursesBySemester[latestSemesterID] = initialCourses
        }

        self.repository = repository
        output = Output(
            semesters: sortedSemesters,
            selectedSemesterID: latestSemesterID,
            coursesBySemester: initialCoursesBySemester
        )
    }

    @discardableResult
    func transform(input: Input) async -> Output {
        switch input {
        case let .selectSemester(id):
            output.selectedSemesterID = id
            output.errorMessage = nil
            await loadCoursesIfNeeded(for: id, force: false)

        case .reloadSelectedSemester:
            guard let selectedSemesterID = output.selectedSemesterID else {
                return output
            }
            output.errorMessage = nil
            await loadCoursesIfNeeded(for: selectedSemesterID, force: true)

        case .errorDismissed:
            output.errorMessage = nil
        }
        return output
    }

    private func loadCoursesIfNeeded(
        for semesterID: SemesterGrade.ID,
        force: Bool
    ) async {
        guard let semester = output.semesters.first(where: { $0.id == semesterID }) else {
            return
        }
        guard force || output.coursesBySemester[semesterID] == nil else {
            return
        }
        guard !output.loadingSemesterIDs.contains(semesterID) else {
            return
        }

        output.loadingSemesterIDs.insert(semesterID)
        defer { output.loadingSemesterIDs.remove(semesterID) }

        do {
            output.coursesBySemester[semesterID] = try await repository.fetchCourses(
                year: semester.year,
                semester: semester.semester
            )
        } catch {
            output.errorMessage = error.localizedDescription
        }
    }
}
