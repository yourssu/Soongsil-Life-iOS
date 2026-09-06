import SwiftUI

struct TimetableView: View {
    @State private var viewModel: TimetableViewModel
    private let onCourseSelected: (TimetableCourseBlock) -> Void

    init(
        viewModel: TimetableViewModel,
        onCourseSelected: @escaping (TimetableCourseBlock) -> Void = { _ in }
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onCourseSelected = onCourseSelected
    }

    var body: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(.white000)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header

                    Rectangle()
                        .fill(.gray100)
                        .frame(height: 1)

                    periodFilter
                        .frame(maxWidth: .infinity)
                        .padding(.top, 17)
                        .padding(.bottom, 28)

                    content
                        .padding(.horizontal, 16)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 24)
            }
            .refreshable {
                await viewModel.transform(input: .load(force: true))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.transform(input: .load())
        }
        .onDisappear {
            viewModel.stopBackgroundPrefetchAfterCurrentRequest()
        }
        .alert(
            L10n.Timetable.loadFailed,
            isPresented: Binding(
                get: {
                    viewModel.output.showsGrid
                        && viewModel.output.errorMessage != nil
                },
                set: { isPresented in
                    guard !isPresented else { return }
                    Task {
                        await viewModel.transform(input: .errorDismissed)
                    }
                }
            )
        ) {
            Button(L10n.Common.confirm, role: .cancel) {
                Task {
                    await viewModel.transform(input: .errorDismissed)
                }
            }
        } message: {
            Text(viewModel.output.errorMessage ?? L10n.Timetable.loadFailed)
        }
    }

    private var header: some View {
        Text(L10n.Timetable.title)
            .font(.pretendard(20, weight: .bold))
            .foregroundStyle(.black000)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .frame(height: 56)
    }

    @ViewBuilder
    private var periodFilter: some View {
        if let selectedPeriod = viewModel.output.selectedPeriod,
           !viewModel.output.availablePeriods.isEmpty {
            Menu {
                ForEach(viewModel.output.availablePeriods, id: \.self) { period in
                    Button {
                        select(period)
                    } label: {
                        let title = L10n.Timetable.periodTitle(
                            year: period.year,
                            semester: period.semester.localizedName
                        )
                        if period == selectedPeriod {
                            Label(title, systemImage: "checkmark")
                        } else {
                            Text(title)
                        }
                    }
                }
            } label: {
                periodFilterLabel(
                    L10n.Timetable.periodTitle(
                        year: selectedPeriod.year,
                        semester: selectedPeriod.semester.localizedName
                    )
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.Timetable.periodFilter)
        }
    }

    private func select(_ period: TimetablePeriod) {
        Task {
            await viewModel.transform(input: .selectPeriod(period))
        }
    }

    private func periodFilterLabel(_ title: String) -> some View {
        HStack(spacing: 6) {
            Text(title)

            Image(systemName: "chevron.down")
                .font(.system(size: 12, weight: .semibold))
        }
        .font(.pretendard(18, weight: .semibold))
        .foregroundStyle(.black000)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var content: some View {
        if let schedule = viewModel.output.schedule, viewModel.output.showsGrid {
            TimetableGridView(schedule: schedule) { block in
                onCourseSelected(block)
            }
        } else if viewModel.output.showsLoading {
            TimetableLoadingView()
        } else if viewModel.output.showsErrorState {
            TimetableErrorStateView(
                errorMessage: viewModel.output.errorMessage
                    ?? L10n.Timetable.loadFailed
            ) {
                Task {
                    await viewModel.transform(input: .load(force: true))
                }
            }
        } else if viewModel.output.showsEmptyState {
            TimetableEmptyStateView()
        }
    }
}

#Preview("Timetable") {
    NavigationStack {
        TimetableView(
            viewModel: TimetableViewModel(
                service: MockTimetableService(delay: .zero)
            )
        )
    }
}

#Preview("강의 없음") {
    NavigationStack {
        TimetableView(
            viewModel: TimetableViewModel(
                service: MockTimetableService(
                    cells: [],
                    delay: .zero
                )
            )
        )
    }
}

#Preview("8시 수업") {
    NavigationStack {
        TimetableView(
            viewModel: TimetableViewModel(
                service: MockTimetableService(
                    cells: MockTimetableFixtures.earlyStartCells,
                    delay: .zero
                )
            )
        )
    }
}
