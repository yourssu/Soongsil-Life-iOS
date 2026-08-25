import Foundation

@Observable
@MainActor
final class NotificationViewModel: BaseViewModel {
    enum Input {
        case load
        case selectCategory(NotificationCategory)
    }

    struct Output {
        var todoList: [CourseTodo] = []
        var selectedCategory: NotificationCategory = .all
        var isLoading = false
        var errorMessage: String?
    }

    private(set) var output = Output()
    private let repository: NotificationRepositoryProtocol

    init(repository: NotificationRepositoryProtocol) {
        self.repository = repository
    }

    @discardableResult
    func transform(input: Input) async -> Output {
        switch input {
        case .load:
            guard !output.isLoading else { return output }
            output.isLoading = true
            output.errorMessage = nil
            do {
                output.todoList = try await repository.fetchLatestTermTodoList()
                    // 마감이 2주 넘게 남은 항목은 올리지 않고, 마감일이 없다면 그대로 둔다.
                    .filter { ($0.daysUntilDue ?? 0) <= 14 }
            } catch {
                output.errorMessage = error.localizedDescription
            }
            output.isLoading = false

        case let .selectCategory(category):
            output.selectedCategory = category
        }
        return output
    }
}

/// 알림 탭 상단 카테고리
enum NotificationCategory: CaseIterable, Hashable {
    case all
    case academic
    case course

    var localizedName: String {
        switch self {
        case .all: NotificationStrings.categoryAll
        case .academic: NotificationStrings.categoryAcademic
        case .course: NotificationStrings.categoryCourse
        }
    }
}

/// 알림 탭 문구
enum NotificationStrings {
    static let categoryAll = "전체"
    static let categoryAcademic = "학사"
    static let categoryCourse = "수업"

    static let kindAssignment = "과제"
    static let kindVideo = "동영상"
    static let kindQuiz = "퀴즈"
    static let kindOther = "할 일"

    static let badgeDDay = "D-Day"
    static let badgeOverdue = "마감 지남"

    static let feedTitle = "이번 학기 할 일"
    static let retention = "중요 알림은 14일 동안 보관돼요"
    static let emptyTitle = "표시할 알림이 없어요"

    static let sectionToday = "오늘"
    static let sectionThisWeek = "이번 주"
    static let sectionPrevious = "이전"

    static let termsFailed = "학기 정보를 불러오지 못했어요."
    static let todoListFailed = "할 일 정보를 불러오지 못했어요."

    static func count(_ value: Int) -> String { "\(value)건" }
}
