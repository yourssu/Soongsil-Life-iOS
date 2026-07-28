import Charts
import SwiftUI

enum MainTabItem: CaseIterable, Hashable {
    case home
    case timetable
    case notification
    case my

    var title: String {
        switch self {
        case .home: L10n.Common.home
        case .timetable: L10n.Common.timetable
        case .notification: L10n.Common.notifications
        case .my: L10n.Common.my
        }
    }

    var assetName: String {
        switch self {
        case .home: "ic_home"
        case .timetable: "ic_calender"
        case .notification: "ic_bell"
        case .my: "ic_person"
        }
    }
}

struct SoomsilTabBar: View {
    @Binding var selectedTab: MainTabItem

    var body: some View {
        HStack(spacing: 4) {
            ForEach(MainTabItem.allCases, id: \.self) { tab in
                let selected = selectedTab == tab
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(tab.assetName)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 18, height: 18)
                        Text(tab.title)
                            .font(.system(size: selected ? 12 : 10, weight: selected ? .semibold : .medium))
                    }
                    .foregroundStyle(selected ? .white : Color.soomsilSecondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(selected ? Color.soomsilBlue600 : .clear)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(6)
        .background(Color.soomsilSurface)
        .clipShape(Capsule())
        .overlay { Capsule().stroke(Color.soomsilBorder, lineWidth: 1) }
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }
}

struct StudentInfoCard: View {
    let profile: StudentProfile

    private var subtitle: String {
        [
            profile.department,
            profile.academicYear,
            profile.enrollmentStatus
        ]
        .compactMap { value in
            guard let value else { return nil }
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        .joined(separator: " · ")
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(profile.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.soomsilPrimaryText)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.soomsilSecondaryText)
                    .lineLimit(1)
            }
            Spacer()
            Text(L10n.Home.studentID(profile.studentID))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.soomsilPrimaryText)
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .background(Color.soomsilMutedSurface)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .soomsilCard(cornerRadius: 10)
    }
}

struct GradeOverviewCard: View {
    let cumulativeGPA: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.Soomsil.reportCardTitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                Text(L10n.Soomsil.total)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(cumulativeGPA.map { String(format: "%.2f", $0) } ?? "-")
                    .font(.system(size: 76, weight: .black))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("/ 4.5")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }

            HStack(spacing: 6) {
                Text(L10n.Soomsil.currentSemesterGrades)
                Image(systemName: "arrow.right")
            }
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Color.soomsilGray950)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.white)
            .clipShape(Capsule())
        }
        .padding(24)
        .background(Color.soomsilGray950)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct GPATrendCard: View {
    private struct DisplayedSemester: Identifiable {
        let semester: SemesterGrade
        let academicIndex: Int

        var id: SemesterGrade.ID { semester.id }
        var axisLabel: String {
            "\(academicIndex / 2 + 1)-\(academicIndex % 2 + 1)"
        }
    }

    let semesters: [SemesterGrade]

    private var displayedSemesters: [DisplayedSemester] {
        let regularSemesters = semesters
            .filter {
                ($0.semester == .first || $0.semester == .second) &&
                $0.gpa > 0
            }
            .sorted {
                let lhs = (Int($0.year) ?? 0, $0.semester.sortOrder)
                let rhs = (Int($1.year) ?? 0, $1.semester.sortOrder)
                return lhs < rhs
            }
            .enumerated()
            .map {
                DisplayedSemester(
                    semester: $0.element,
                    academicIndex: $0.offset
                )
            }
        return Array(regularSemesters.suffix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(L10n.Soomsil.overallSemesterTrend)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.soomsilPrimaryText)
                Spacer()
                HStack(spacing: 4) {
                    Text(L10n.Soomsil.details)
                    Image(systemName: "chevron.right")
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.soomsilBlue600)
            }

            Chart(displayedSemesters) { item in
                let isLatest = item.id == displayedSemesters.last?.id
                BarMark(
                    x: .value("semester", item.axisLabel),
                    y: .value("gpa", item.semester.gpa),
                    width: .ratio(0.68)
                )
                .foregroundStyle(
                    isLatest
                    ? Color.soomsilGray950
                    : (
                        item.academicIndex.isMultiple(of: 2)
                        ? Color.soomsilBlue100
                        : Color.soomsilBlue200
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .annotation(position: .top, spacing: 5) {
                    if isLatest {
                        Text(String(format: "%.2f", item.semester.gpa))
                            .font(.system(size: 11, weight: .bold))
                    }
                }
            }
            .chartYScale(domain: 0...4.5)
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks { _ in
                    AxisTick().foregroundStyle(.clear)
                    AxisValueLabel()
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.soomsilSecondaryText)
                }
            }
            .frame(height: 116)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .soomsilCard(cornerRadius: 20)
    }
}

struct ChapelAttendanceCard: View {
    enum Style {
        case compact
        case detailed
    }

    let chapel: ChapelStatus?
    let style: Style

    private let requiredCount = 8

    private var attendanceCount: Int {
        guard let chapel else { return 0 }
        return min(
            chapel.attendance.filter { $0.status.isPresent }.count,
            requiredCount
        )
    }

    private var lateCount: Int {
        chapel?.attendance.filter { $0.status == .late }.count ?? 0
    }

    private var attendancePercentage: Int {
        guard requiredCount > 0 else { return 0 }
        return Int(
            (Double(attendanceCount) / Double(requiredCount) * 100).rounded()
        )
    }

    var body: some View {
        switch style {
        case .compact:
            compactCard
        case .detailed:
            detailedCard
        }
    }

    private var compactCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.Soomsil.chapelAttendance)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.soomsilPrimaryText)
                    Text(L10n.Soomsil.attendanceSummary(attendanceCount, requiredCount))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.soomsilBlue500)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.soomsilSlate400)
            }

            progressBar
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .soomsilCard(cornerRadius: 12)
    }

    private var detailedCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(L10n.Soomsil.remainingAttendance)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.soomsilPrimaryText)
                Spacer()
                Text(L10n.Soomsil.attendanceCount(attendanceCount, requiredCount))
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(Color.soomsilBlue600)
            }

            progressBar

            Text(
                L10n.Soomsil.attendanceDetail(
                    attendance: attendanceCount,
                    late: lateCount,
                    percentage: attendancePercentage
                )
            )
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(Color.soomsilSecondaryText)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity)
        .background(Color.soomsilMutedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.soomsilGray100)
                Capsule()
                    .fill(Color.soomsilBlue600)
                    .frame(
                        width: proxy.size.width *
                        CGFloat(attendanceCount) /
                        CGFloat(requiredCount)
                    )
            }
        }
        .frame(height: 7)
        .accessibilityLabel(L10n.Soomsil.chapelAttendance)
        .accessibilityValue(
            L10n.Soomsil.attendanceCount(attendanceCount, requiredCount)
        )
    }
}

struct ChapelSeatCard: View {
    let chapel: ChapelStatus

    private var seatPosition: String {
        chapel.seat.components(separatedBy: .whitespaces).joined()
    }

    private var seatZone: String {
        seatPosition
            .split(separator: "-")
            .first
            .map(String.init) ?? "A"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(L10n.Soomsil.mySeat)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
            Text(seatPosition)
                .font(.system(size: 44, weight: .black))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Divider().overlay(.white.opacity(0.16))
            HStack {
                Text(
                    L10n.Soomsil.chapelSeatDescription(
                        classroom: chapel.classroom,
                        zone: seatZone
                    )
                )
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                Text(L10n.Soomsil.seatLocation)
                    .font(.system(size: 12, weight: .bold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(.white)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.soomsilBlue600)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

enum HomeShortcutIcon {
    case graduation
    case tuition
}

struct HomeShortcutCard: View {
    let title: String
    let icon: HomeShortcutIcon

    var body: some View {
        VStack(spacing: 10) {
            shortcutIcon
                .frame(width: 48, height: 48)
                .background(iconBackground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.soomsilPrimaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 112)
        .padding(.horizontal, 12)
        .background(Color.soomsilMutedSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    @ViewBuilder
    private var shortcutIcon: some View {
        switch icon {
        case .graduation:
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.soomsilGray950)
        case .tuition:
            Text("₩")
                .font(.system(size: 25, weight: .black))
                .foregroundStyle(Color.soomsilGreen500)
        }
    }

    private var iconBackground: Color {
        switch icon {
        case .graduation: Color.soomsilBlue50
        case .tuition: Color.soomsilGreen50
        }
    }
}

struct CourseGradeRow: View {
    let course: CourseGrade

    var body: some View {
        HStack(spacing: 12) {
            Text(course.grade)
                .font(.system(size: 15, weight: .black))
                .foregroundStyle(Color.soomsilBlue600)
                .frame(width: 44, height: 44)
                .background(Color.soomsilBlue50)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(course.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.soomsilPrimaryText)
                    .lineLimit(1)
                Text(L10n.Grades.courseDetail(professor: course.professor, credits: course.credits))
                    .font(.system(size: 12))
                    .foregroundStyle(Color.soomsilSecondaryText)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .soomsilCard(cornerRadius: 16)
    }
}

struct SoomsilLoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.12).ignoresSafeArea()
            ProgressView()
                .controlSize(.large)
                .tint(Color.soomsilBlue600)
                .padding(28)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }
}

#Preview("Dashboard components") {
    ScrollView {
        VStack(spacing: 16) {
            StudentInfoCard(profile: MockLMSFixtures.profile)
            GradeOverviewCard(
                cumulativeGPA: MockLMSFixtures.dashboard.cumulativeGPA
            )
            GPATrendCard(semesters: MockLMSFixtures.semesters)
            ChapelAttendanceCard(
                chapel: MockLMSFixtures.chapel,
                style: .detailed
            )
            ChapelSeatCard(chapel: MockLMSFixtures.chapel)
            HStack {
                HomeShortcutCard(
                    title: L10n.Home.graduationAudit,
                    icon: .graduation
                )
                HomeShortcutCard(
                    title: L10n.Home.tuitionScholarship,
                    icon: .tuition
                )
            }
            CourseGradeRow(course: MockLMSFixtures.courses[1])
        }
        .padding(20)
    }
    .background(Color.soomsilBackground)
}
