import SwiftUI

struct ChapelTabView: View {
    @State var viewModel: HomeViewModel
    @State private var showsInfo = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                if let chapel = viewModel.output.dashboard?.chapel {
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
                } else if viewModel.output.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ContentUnavailableView(
                        L10n.Chapel.title,
                        systemImage: "sofa.fill",
                        description: Text(viewModel.output.errorMessage ?? L10n.Soomsil.noChapel)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .navigationTitle(L10n.Soomsil.seatLocation)
        .navigationBarTitleDisplayMode(.inline)
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
        viewModel: HomeViewModel(repository: container.homeRepository)
    )
}

#Preview("Chapel seat") {
    NavigationStack {
        ChapelDetailView(chapel: MockLMSFixtures.chapel)
    }
}
