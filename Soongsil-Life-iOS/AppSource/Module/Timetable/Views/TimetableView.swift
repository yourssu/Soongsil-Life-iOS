import SwiftUI

struct TimetableView: View {
    @State private var viewModel: TimetableViewModel
    @State private var selectedBlock: TimetableCourseBlock?

    init(viewModel: TimetableViewModel? = nil) {
        _viewModel = State(initialValue: viewModel ?? TimetableViewModel())
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.soomsilBackground
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    content
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 110)
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
    }

    private var header: some View {
        Text("수업 시간표")
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(Color.soomsilPrimaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 10)
    }

    @ViewBuilder
    private var content: some View {
        if let schedule = viewModel.output.schedule, viewModel.output.showsGrid {
            VStack(spacing: 12) {
                if !schedule.title.isEmpty {
                    Text(schedule.title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.soomsilPrimaryText)
                        .frame(maxWidth: .infinity)
                }

                TimetableGridView(schedule: schedule) { block in
                    selectedBlock = block
                }
            }
        } else if viewModel.output.showsLoading {
            TimetableLoadingView()
        } else if viewModel.output.showsEmptyState {
            TimetableEmptyStateView(errorMessage: viewModel.output.errorMessage) {
                Task {
                    await viewModel.transform(input: .load(force: true))
                }
            }
        }
    }
}

#Preview("Timetable") {
    NavigationStack {
        TimetableView(
            viewModel: TimetableViewModel(
                service: MockTimetableService(delayNanoseconds: 0)
            )
        )
    }
}

#Preview("강의 없음") {
    NavigationStack {
        TimetableView(
            viewModel: TimetableViewModel(
                service: MockTimetableService(cells: [], delayNanoseconds: 0)
            )
        )
    }
}
