import SwiftUI

struct NotificationView: View {
    @State private var viewModel: NotificationViewModel

    init(viewModel: NotificationViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                feedSummary
                categoryTabs
                retentionBanner
                todoSections
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(Color.soomsilBackground)
        .navigationTitle(L10n.Common.notifications)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.transform(input: .load)
        }
        .refreshable {
            await viewModel.transform(input: .load)
        }
        .overlay {
            if viewModel.output.isLoading && viewModel.output.todoList.isEmpty {
                SoomsilLoadingOverlay()
            }
        }
    }

    //상단

    private var feedSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(NotificationStrings.feedTitle)
                .font(.system(size: 13))
                .foregroundStyle(Color.soomsilSecondaryText)

            Text(NotificationStrings.count(viewModel.output.todoList.count))
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Color.soomsilPrimaryText)
        }
    }

    //카테고리

    private var categoryTabs: some View {
        HStack(spacing: 30) {
            ForEach(NotificationCategory.allCases, id: \.self) { category in
                let selected = viewModel.output.selectedCategory == category
                Button {
                    Task {
                        await viewModel.transform(input: .selectCategory(category))
                    }
                } label: {
                    Text(category.localizedName)
                        .font(.system(size: 13, weight: selected ? .bold : .medium))
                        .foregroundStyle(
                            selected
                                ? Color.soomsilPrimaryText
                                : Color.soomsilSecondaryText
                        )
                        .padding(.bottom, 5)
                        .overlay(alignment: .bottom) {
                            Rectangle()
                                .fill(selected ? Color.soomsilPrimaryText : Color.clear)
                                .frame(height: 2)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
            Spacer()
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.soomsilBorder)
                .frame(height: 1)
        }
    }
    
    private var retentionBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle")
            Text(NotificationStrings.retention)
        }
        .font(.system(size: 12))
        .foregroundStyle(Color.soomsilSecondaryText)
    }

    //목록
    //오늘 / 이번 주 / 이전으로 나누고, 학사공지는 아직 구현하지 못하여 빈 배열로 반환
    
    private var sections: [(title: String, todoList: [CourseTodo])] {
        let todoList = viewModel.output.selectedCategory == .academic
            ? []
            : viewModel.output.todoList

        return [
            (NotificationStrings.sectionToday,
             todoList.filter { $0.daysUntilDue == 0 }),
            (NotificationStrings.sectionThisWeek,
             todoList.filter { ($0.daysUntilDue ?? -1) > 0 }),
            (NotificationStrings.sectionPrevious,
             todoList.filter { ($0.daysUntilDue ?? -1) < 0 })
        ].filter { !$0.todoList.isEmpty }
    }

    @ViewBuilder
    private var todoSections: some View {
        if let errorMessage = viewModel.output.errorMessage {
            errorCard(errorMessage)
        } else if sections.isEmpty {
            emptyState
        } else {
            LazyVStack(alignment: .leading, spacing: 20) {
                ForEach(sections, id: \.title) { section in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 6) {
                            Text(section.title)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(Color.soomsilPrimaryText)
                            Text(NotificationStrings.count(section.todoList.count))
                                .font(.system(size: 12))
                                .foregroundStyle(Color.soomsilSecondaryText)
                        }

                        VStack(spacing: 10) {
                            ForEach(section.todoList) { todo in
                                TodoRow(todo: todo)
                            }
                        }
                    }
                }
            }
        }
    }

    private func errorCard(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.soomsilSecondaryText)
                .multilineTextAlignment(.center)
            Button(L10n.Home.retryDescription) {
                Task {
                    await viewModel.transform(input: .load)
                }
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Color.soomsilBlue600)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .soomsilCard(cornerRadius: 16)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "bell.slash")
                .font(.system(size: 30))
                .foregroundStyle(Color.soomsilSecondaryText)
            Text(NotificationStrings.emptyTitle)
                .font(.system(size: 14))
                .foregroundStyle(Color.soomsilSecondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}


//할일 카드

private struct TodoRow: View {
    let todo: CourseTodo

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(todo.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.soomsilPrimaryText)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)

                Text("\(todo.subjectName) \(todo.kind.localizedName) · \(Self.dueText(todo.dueDate))")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.soomsilSecondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            DueBadgeView(badge: .forTodo(todo))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Color.soomsilMutedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    /// 제출 마감 시각을 보여줌. 오늘 마감이면 "오늘 09:40", 아니면 "5월 8일 17:00".
    private static func dueText(_ date: Date?) -> String {
        guard let date else { return "마감일 없음" }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        formatter.dateFormat = Calendar.current.isDateInToday(date)
            ? "'오늘' HH:mm"
            : "M월 d일 HH:mm"
        return formatter.string(from: date)
    }
}


//마감일지 뱃지

enum DueBadge: Equatable {
    /// 마감까지 남은 일수
    case dDay(Int)
    case overdue
    /// 마감일이 없어 뱃지를 붙이지 않는 경우
    case none

    static func forTodo(_ todo: CourseTodo) -> DueBadge {
        guard let remaining = todo.daysUntilDue else { return .none }

        return remaining < 0 ? .overdue : .dDay(remaining)
    }

    var text: String {
        switch self {
        case let .dDay(remaining):
            remaining == 0 ? NotificationStrings.badgeDDay : "D-\(remaining)"
        case .overdue: NotificationStrings.badgeOverdue
        case .none: ""
        }
    }
}

//디데이 계산 및 컬러 매칭
private struct DueBadgeView: View {
    let badge: DueBadge

    var body: some View {
        if badge != .none {
            Text(badge.text)
                .font(.system(size: 11, weight: .bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .foregroundStyle(foreground)
                .background(background)
                .clipShape(Capsule())
        }
    }

    private var foreground: Color {
        switch badge {
        case let .dDay(remaining) where remaining <= 1:
            Color.soomsilRed500
        case let .dDay(remaining) where remaining <= 4:
            Color.soomsilOrange500
        case .dDay:
            Color.soomsilSecondaryText
        case .overdue:
            Color.soomsilRed500
        case .none:
            Color.clear
        }
    }

    private var background: Color {
        switch badge {
        case let .dDay(remaining) where remaining <= 1:
            Color.soomsilRed50
        case let .dDay(remaining) where remaining <= 4:
            Color.soomsilOrange50
        case .dDay:
            Color.soomsilGray100
        case .overdue:
            Color.soomsilRed50
        case .none:
            Color.clear
        }
    }
}



#Preview("Notification") {
    NavigationStack {
        NotificationView(
            viewModel: NotificationViewModel(
                repository: NotificationRepository(
                    service: MockNotificationService(delayNanoseconds: 0)
                )
            )
        )
    }
}
