import Foundation
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

                case .completed:
                    ContentUnavailableView(
                        L10n.Soomsil.noChapelTitle,
                        systemImage: "checkmark.circle.fill",
                        description: Text(L10n.Soomsil.noChapel)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .notEnrolled:
                    ContentUnavailableView(
                        L10n.Soomsil.notTakingChapelTitle,
                        systemImage: "sofa.fill",
                        description: Text(L10n.Soomsil.notTakingChapel)
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(.white000)
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
        .tint(.black000)
    }

    private var header: some View {
        HStack {
            Text(L10n.Chapel.title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.black000)
            Spacer()
            Button {
                showsInfo = true
            } label: {
                Image("ic_info")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundStyle(.gray500)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

struct ChapelDetailView: View {
    let chapel: ChapelStatus

    @State private var showsAbsenceInfo = false

    private let semesterSessionCount = ChapelAttendancePolicy.semesterSessionCount
    private let allowedAbsenceCount = ChapelAttendancePolicy.allowedAbsenceCount

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                seatSummary

                ZoomableChapelSeatMapView(seat: chapel.seat)
                    .padding(.horizontal, 20)
                    .padding(.top, 38)
            }
            .padding(.top, 29)
            .padding(.bottom, 40)
        }
        .background(.white000)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.editor)
        .tint(.black000)
        .toolbarBackground(.white000, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var seatSummary: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L10n.Soomsil.mySeat)
                .font(.pretendard(14, weight: .medium))
                .foregroundStyle(.black000)

            Text(chapel.seat.isEmpty ? "-" : chapel.seat)
                .font(.pretendard(32, weight: .bold))
                .foregroundStyle(.serviceBlue500)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.top, 5)

            VStack(spacing: 17) {
                countRow(
                    title: "출석 현황",
                    numerator: String(attendanceCount),
                    denominator: String(semesterSessionCount)
                )
                countRow(
                    title: "결석 현황",
                    numerator: absenceCount,
                    denominator: String(allowedAbsenceCount),
                    showsInformationIcon: true
                )
                valueRow(title: "다음 출석일", value: nextAttendanceText)
            }
            .padding(.top, 29)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func countRow(
        title: String,
        numerator: String,
        denominator: String,
        showsInformationIcon: Bool = false
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            HStack(spacing: 5) {
                Text(title)
                    .font(.pretendard(15))
                    .foregroundStyle(.serviceGray500)

                if showsInformationIcon {
                    Button {
                        showsAbsenceInfo.toggle()
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(.serviceGray500)
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("결석 처리 기준 안내")
                    .popover(
                        isPresented: $showsAbsenceInfo,
                        attachmentAnchor: .rect(.bounds),
                        arrowEdge: .top
                    ) {
                        Text("지각 2회 시 결석 1회 처리")
                            .font(.pretendard(13, weight: .medium))
                            .foregroundStyle(.serviceBlue500)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .fixedSize()
                            .presentationBackground(.serviceGray200)
                            .presentationCompactAdaptation(.popover)
                    }
                }
            }

            Spacer(minLength: 16)

            Text(numerator)
                .font(.pretendard(16, weight: .semibold))
                .foregroundStyle(.black000)
            Text("/ \(denominator)")
                .font(.pretendard(12))
                .foregroundStyle(.serviceGray500)
        }
    }

    private func valueRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(title)
                .font(.pretendard(15))
                .foregroundStyle(.serviceGray500)

            Spacer(minLength: 16)

            Text(value)
                .font(.pretendard(16, weight: .semibold))
                .foregroundStyle(.black000)
        }
    }

    private var attendanceCount: Int {
        ChapelAttendancePolicy.creditedAttendanceCount(
            in: chapel.attendance
        )
    }

    private var absenceCount: String {
        let numericValue = chapel.absenceCount.filter(\.isNumber)
        let reportedCount = Int(numericValue) ?? 0
        let calculatedCount = ChapelAttendancePolicy.calculatedAbsenceCount(
            in: chapel.attendance
        )
        return String(max(reportedCount, calculatedCount))
    }

    private var nextAttendanceText: String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let today = calendar.startOfDay(for: Date())

        let nextDate = chapel.attendance.compactMap { attendance -> Date? in
            guard case .unknown = attendance.status,
                  let date = parsedDate(attendance.date),
                  date >= today
            else { return nil }
            return date
        }
        .min()

        return nextDate.map(displayedDate) ?? "-"
    }

    private func parsedDate(_ value: String) -> Date? {
        let formats = ["yyyy.MM.dd", "yyyy-MM-dd", "yyyy/MM/dd"]
        for format in formats {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.locale = Locale(identifier: "ko_KR")
            formatter.dateFormat = format
            if let date = formatter.date(from: value) {
                return date
            }
        }
        return nil
    }

    private func displayedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "MM / dd (EEE)"
        return formatter.string(from: date)
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
