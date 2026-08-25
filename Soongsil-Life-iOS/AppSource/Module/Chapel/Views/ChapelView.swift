import SwiftUI

struct ChapelTabView: View {
    @State private var viewModel: ChapelViewModel
    @State private var showsInfo = false

    init(viewModel: ChapelViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                switch viewModel.output.loadState {
                case let .loaded(chapel):
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 12) {
                            NavigationLink {
                                ChapelDetailView(chapel: chapel)
                            } label: {
                                ChapelSeatCard(chapel: chapel)
                            }
                            .buttonStyle(.plain)

                            ChapelAttendanceCard(chapel: chapel, style: .detailed)
                        }
                        .padding(.horizontal, 29)
                        .padding(.vertical, 8)
                    }

                case .idle, .loading:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                case let .failed(errorMessage):
                    ContentUnavailableView {
                        Label(
                            L10n.Chapel.loadFailed,
                            systemImage: "wifi.exclamationmark"
                        )
                    } description: {
                        Text(errorMessage)
                    } actions: {
                        Button(L10n.Common.retry) {
                            Task {
                                await viewModel.transform(input: .load(force: true))
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                case let .notEnrolled(completedSemesterCount):
                    if completedSemesterCount >= 6 {
                        ContentUnavailableView(
                            L10n.Soomsil.noChapelTitle,
                            systemImage: "checkmark.circle.fill",
                            description: Text(L10n.Soomsil.noChapel)
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ContentUnavailableView(
                            L10n.Soomsil.notTakingChapelTitle,
                            systemImage: "sofa.fill",
                            description: Text(L10n.Soomsil.notTakingChapel)
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .background(Color.soomsilBackground)
            .toolbar(.hidden, for: .navigationBar)
            .task {
                await viewModel.transform(input: .load())
            }
            .alert(L10n.Chapel.title, isPresented: $showsInfo) {
                Button(L10n.Common.confirm, role: .cancel) {}
            } message: {
                Text(L10n.Soomsil.chapelInfo)
            }
        }
    }

    private var header: some View {
        HStack {
            Text(L10n.Chapel.title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.soomsilPrimaryText)
            Spacer()
            Button {
                showsInfo = true
            } label: {
                Image("ic_info")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(Color.soomsilGray500)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

struct ChapelDetailView: View {
    let chapel: ChapelStatus

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.Soomsil.mySeat)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.soomsilSecondaryText)
                    Text(chapel.seat)
                        .font(.system(size: 32, weight: .black))
                        .foregroundStyle(Color.soomsilBlue500)
                    Text(chapel.classroom)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.soomsilSecondaryText)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .soomsilCard(cornerRadius: 20)

                VStack(spacing: 4) {
                    ZoomableChapelSeatMapView(seat: chapel.seat)

                    Text(ChapelSeatLocation(seat: chapel.seat).guideText)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.soomsilSecondaryText)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }

                VStack(spacing: 0) {
                    ForEach(chapel.attendance) { item in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.date)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(Color.soomsilPrimaryText)
                                Text(attendanceDetail(item))
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.soomsilSecondaryText)
                            }
                            Spacer()
                            Text(item.status.localizedName)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(item.status.isPresent ? Color.soomsilGreen500 : .red)
                        }
                        .padding(16)

                        if item.id != chapel.attendance.last?.id {
                            Divider().padding(.horizontal, 16)
                        }
                    }
                }
                .soomsilCard(cornerRadius: 16)
            }
            .padding(20)
        }
        .background(Color.soomsilBackground)
        .soomsilDetailNavigation(title: L10n.Soomsil.seatLocation)
    }

    private func attendanceDetail(_ attendance: ChapelAttendance) -> String {
        [attendance.lectureType, attendance.classGroup]
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }
}

#Preview("Chapel") {
    let container = DIContainer.preview
    ChapelTabView(
        viewModel: ChapelViewModel(repository: container.chapelRepository)
    )
}

#Preview("Chapel seat") {
    NavigationStack {
        ChapelDetailView(chapel: MockLMSFixtures.chapel)
    }
}
