import SwiftUI

struct TimetableView: View {
    @State private var viewModel: TimetableViewModel
    @State private var selectedBlock: TimetableCourseBlock?

    init(viewModel: TimetableViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.soomsilBackground

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    periodFilter
                    content
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
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
        .sheet(item: $selectedBlock) { block in
            TimetableCourseDetailSheet(block: block) {
                selectedBlock = nil
            }
            .presentationDetents([.height(320)])
            .presentationCornerRadius(20)
            .presentationDragIndicator(.visible)
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
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(Color.soomsilPrimaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 10)
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
                .font(.system(size: 11, weight: .bold))
        }
        .font(.system(size: 15, weight: .bold))
        .foregroundStyle(Color.soomsilPrimaryText)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(Color.soomsilMutedSurface)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(Color.soomsilBorder, lineWidth: 1)
        }
    }

    @ViewBuilder
    private var content: some View {
        if let schedule = viewModel.output.schedule, viewModel.output.showsGrid {
            TimetableGridView(schedule: schedule) { block in
                selectedBlock = block
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
