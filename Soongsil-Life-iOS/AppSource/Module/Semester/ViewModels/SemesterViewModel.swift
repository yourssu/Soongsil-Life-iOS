import Foundation

@Observable
@MainActor
final class SemesterViewModel: BaseViewModel {
    private struct CourseRequest {
        let id: UUID
        let task: Task<Void, Never>
    }

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
    private var activeCourseRequest: CourseRequest?

    init(
        repository: GradeRepositoryProtocol,
        semesters: [SemesterGrade],
        initialCourses: [CourseGrade]? = nil
    ) {
        let sortedSemesters = semesters.sorted {
            let lhs = (Int($0.year) ?? 0, $0.semester.sortOrder)
            let rhs = (Int($1.year) ?? 0, $1.semester.sortOrder)
            return lhs < rhs
        }
        let latestSemesterID = sortedSemesters.last?.id
        var initialCoursesBySemester: [SemesterGrade.ID: [CourseGrade]] = [:]
        if let latestSemesterID, let initialCourses {
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

        output.loadingSemesterIDs.insert(semesterID)
        defer { output.loadingSemesterIDs.remove(semesterID) }

        while let activeCourseRequest {
            await activeCourseRequest.task.value
            if self.activeCourseRequest?.id == activeCourseRequest.id {
                self.activeCourseRequest = nil
            }
        }

        // 여러 학기를 빠르게 눌렀다면 대기 중이던 예전 선택은 추가 요청하지 않습니다.
        guard !Task.isCancelled else { return }
        guard output.selectedSemesterID == semesterID else { return }
        guard force || output.coursesBySemester[semesterID] == nil else { return }

        let request = CourseRequest(
            id: UUID(),
            task: Task { @MainActor [weak self, repository] in
                guard let self else { return }
                do {
                    output.coursesBySemester[semesterID] = try await repository.fetchCourses(
                        year: semester.year,
                        semester: semester.semester
                    )
                } catch is CancellationError {
                    return
                } catch {
                    if output.selectedSemesterID == semesterID {
                        output.errorMessage = error.localizedDescription
                    }
                }
            }
        )
        activeCourseRequest = request
        await request.task.value
        if activeCourseRequest?.id == request.id {
            activeCourseRequest = nil
        }
    }
}
