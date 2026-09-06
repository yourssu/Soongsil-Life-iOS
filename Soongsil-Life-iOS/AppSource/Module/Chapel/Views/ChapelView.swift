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
            Group {
                switch viewModel.output.loadState {
                case let .loaded(chapel):
                    loadedContent(chapel)

                case .idle, .loading:
                    VStack(spacing: 0) {
                        header

                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                case let .failed(errorMessage):
                    VStack(spacing: 0) {
                        header

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
                    }

                case .completed:
                    VStack(spacing: 0) {
                        header

                        ContentUnavailableView(
                            L10n.Soomsil.noChapelTitle,
                            systemImage: "checkmark.circle.fill",
                            description: Text(L10n.Soomsil.noChapel)
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                case .notEnrolled:
                    VStack(spacing: 0) {
                        header

                        ContentUnavailableView(
                            L10n.Soomsil.notTakingChapelTitle,
                            systemImage: "sofa.fill",
                            description: Text(L10n.Soomsil.notTakingChapel)
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .background(.white000)
            .toolbar(.hidden, for: .navigationBar)
            .alert(L10n.Chapel.title, isPresented: $showsInfo) {
                Button(L10n.Common.confirm, role: .cancel) {}
            } message: {
                Text(L10n.Soomsil.chapelInfo)
            }
        }
        .tint(.black000)
        .task {
            await viewModel.transform(input: .load())
        }
    }

    private func loadedContent(_ chapel: ChapelStatus) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                header

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
        }
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
        .frame(height: 56)
    }
}

struct ChapelDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let chapel: ChapelStatus

    @State private var showsAbsenceInfo = false

    private let semesterSessionCount = ChapelAttendancePolicy.semesterSessionCount
    private let allowedAbsenceCount = ChapelAttendancePolicy.allowedAbsenceCount

    var body: some View {
        ZStack(alignment: .topLeading) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: 56)

                    VStack(spacing: 0) {
                        seatSummary

                        ZoomableChapelSeatMapView(seat: chapel.seat)
                            .padding(.horizontal, 20)
                            .padding(.top, 38)
                    }
                    .padding(.top, 29)
                }
                .padding(.bottom, 40)
            }

            fixedBackButton
                .padding(.leading, 8)
                .padding(.top, 6)
                .zIndex(1)
        }
        .background(.white000)
        .toolbar(.hidden, for: .navigationBar)
        .toolbarRole(.editor)
        .soomsilInteractivePopGesture()
        .tint(.black000)
    }

    private var fixedBackButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.black000)
                .frame(width: 44, height: 44)
                .background(.white000, in: Circle())
                .shadow(
                    color: .black000.opacity(0.06),
                    radius: 16,
                    x: 0,
                    y: 8
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("뒤로")
        .frame(width: 44, height: 44)
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
                        withAnimation(.easeOut(duration: 0.15)) {
                            showsAbsenceInfo.toggle()
                        }
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(.serviceGray500)
                            .frame(width: 24, height: 24)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("결석 처리 기준 안내")
                    .overlay(alignment: .topLeading) {
                        if showsAbsenceInfo {
                            ChapelAbsenceTooltip()
                                .offset(x: -12, y: 28)
                                .transition(
                                    .opacity.combined(
                                        with: .scale(
                                            scale: 0.96,
                                            anchor: .topLeading
                                        )
                                    )
                                )
                                .allowsHitTesting(false)
                        }
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
        .zIndex(showsInformationIcon && showsAbsenceInfo ? 1 : 0)
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

private struct ChapelAbsenceTooltip: View {
    var body: some View {
        ZStack(alignment: .top) {
            ChapelAbsenceTooltipShape()
                .fill(.serviceGray200)

            Text("지각 2회 시 결석 1회 처리")
                .font(.pretendard(13, weight: .medium))
                .foregroundStyle(.serviceBlue500)
                .lineLimit(1)
                .frame(width: 152, height: 29)
                .offset(y: 5)
        }
        .frame(width: 152, height: 34)
        .accessibilityHidden(true)
    }
}

private struct ChapelAbsenceTooltipShape: Shape {
    func path(in rect: CGRect) -> Path {
        let arrowHeight: CGFloat = 5
        let arrowCenterX: CGFloat = 24
        let arrowHalfWidth: CGFloat = 4
        let cornerRadius: CGFloat = 6

        var path = Path(
            roundedRect: CGRect(
                x: rect.minX,
                y: rect.minY + arrowHeight,
                width: rect.width,
                height: rect.height - arrowHeight
            ),
            cornerRadius: cornerRadius
        )
        path.move(to: CGPoint(x: arrowCenterX, y: rect.minY))
        path.addLine(
            to: CGPoint(
                x: arrowCenterX + arrowHalfWidth,
                y: rect.minY + arrowHeight
            )
        )
        path.addLine(
            to: CGPoint(
                x: arrowCenterX - arrowHalfWidth,
                y: rect.minY + arrowHeight
            )
        )
        path.closeSubpath()
        return path
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
