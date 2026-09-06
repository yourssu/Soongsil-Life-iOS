import Charts
import SwiftUI

enum MainTabItem: CaseIterable, Hashable {
    case home
    case chapel
    case timetable
    case my

    static let visibleItems: [MainTabItem] = [
        .home,
        .timetable,
        .my
    ]

    var title: String {
        switch self {
        case .home: L10n.Common.home
        case .chapel: L10n.Chapel.title
        case .timetable: L10n.Common.timetable
        case .my: L10n.Common.my
        }
    }

    var assetName: String {
        switch self {
        case .home: "ic_home"
        case .chapel: "ic_sofa"
        case .timetable: "ic_calender"
        case .my: "ic_person"
        }
    }

    func assetName(isSelected: Bool) -> String {
        guard isSelected else {
            return assetName
        }

        switch self {
        case .home:
            return "ic_home_fill"
        case .timetable:
            return "ic_calender_fill"
        case .my:
            return "ic_person_fill"
        case .chapel:
            return assetName
        }
    }
}

struct SoomsilTabBar: View {
    @Binding var selectedTab: MainTabItem

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTabItem.visibleItems, id: \.self) { tab in
                let selected = selectedTab == tab
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 3) {
                        Image(tab.assetName(isSelected: selected))
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                        Text(tab.title)
                            .font(.pretendard(13, weight: .medium))
                    }
                    .foregroundStyle(
                        selected ? .serviceBlue600 : .serviceGray500
                    )
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background {
                        if selected {
                            Capsule()
                                .fill(
                                    .black000.opacity(0.08)
                                        .shadow(
                                            .inner(
                                                color: .white000.opacity(0.25),
                                                radius: 4,
                                                x: 0,
                                                y: 4
                                            )
                                        )
                                )
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(8)
        .background {
            Capsule()
                .fill(
                    .white000.shadow(
                        .inner(
                            color: .realBlack.opacity(0.02),
                            radius: 7,
                            x: 7,
                            y: 7
                        )
                    )
                )
                .overlay {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .gray100.opacity(0.35),
                                    .gray100.opacity(0)
                                ],
                                startPoint: .topLeading,
                                endPoint: UnitPoint(x: 0.58, y: 0.72)
                            )
                        )
                }
        }
        .clipShape(Capsule())
        .padding(.horizontal, 22)
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
                    .foregroundStyle(.black000)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(.gray600)
                    .lineLimit(1)
            }
            Spacer()
            Text(L10n.Home.studentID(profile.studentID))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.black000)
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                .background(.gray050)
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
    let earnedCredits: Double
    let semesterRank: String
    let totalRank: String

    private let graduationCredits = 133

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("전체 평균")
                .font(.pretendard(15, weight: .semibold))
                .foregroundStyle(.black000)

            HStack(alignment: .lastTextBaseline, spacing: 7) {
                Text(cumulativeGPA.map { String(format: "%.2f", $0) } ?? "-")
                    .font(.pretendard(40, weight: .bold))
                    .foregroundStyle(.black000)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("/ 4.50")
                    .font(.pretendard(15, weight: .medium))
                    .foregroundStyle(.serviceGray500)
            }
            .padding(.top, 7)

            VStack(spacing: 17) {
                metricRow(
                    title: "취득 학점",
                    numerator: formattedCredits,
                    denominator: "\(graduationCredits)"
                )
                metricRow(title: "학기별 석차", value: semesterRank)
                metricRow(title: "전체 석차", value: totalRank)
            }
            .padding(.top, 27)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var formattedCredits: String {
        if earnedCredits.rounded() == earnedCredits {
            return String(Int(earnedCredits))
        }
        return String(format: "%.1f", earnedCredits)
    }

    private func metricRow(title: String, value: String) -> some View {
        let parts = rankParts(value)
        return metricRow(
            title: title,
            numerator: parts.numerator,
            denominator: parts.denominator
        )
    }

    private func metricRow(
        title: String,
        numerator: String,
        denominator: String
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(title)
                .font(.pretendard(15))
                .foregroundStyle(.serviceGray500)

            Spacer(minLength: 16)

            Text(numerator)
                .font(.pretendard(16, weight: .semibold))
                .foregroundStyle(.black000)

            Text("/ \(denominator)")
                .font(.pretendard(12))
                .foregroundStyle(.serviceGray500)
        }
    }

    private func rankParts(_ value: String) -> (
        numerator: String,
        denominator: String
    ) {
        let parts = value
            .split(separator: "/", maxSplits: 1)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        guard parts.count == 2 else {
            return (value.isEmpty ? "-" : value, "-")
        }
        return (parts[0], parts[1])
    }
}

struct GPATrendCard: View {
    private struct DisplayedSemester: Identifiable {
        let semester: SemesterGrade
        let academicIndex: Int
        let plotPosition: Double

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
        let visibleSemesters = Array(regularSemesters.suffix(8))
        let firstAcademicIndex = regularSemesters.count - visibleSemesters.count

        return visibleSemesters
            .enumerated()
            .map { plotIndex, semester in
                DisplayedSemester(
                    semester: semester,
                    academicIndex: firstAcademicIndex + plotIndex,
                    plotPosition: Double(plotIndex)
                )
            }
    }

    private var xDomain: ClosedRange<Double> {
        guard displayedSemesters.count > 1 else {
            return -0.5...0.5
        }
        return 0...Double(displayedSemesters.count - 1)
    }

    var body: some View {
        Chart {
            ForEach(displayedSemesters) { item in
                AreaMark(
                    x: .value("semester", item.plotPosition),
                    yStart: .value("minimum", 0),
                    yEnd: .value("gpa", item.semester.gpa)
                )
                .interpolationMethod(.linear)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            .serviceBlue500.opacity(0.22),
                            .serviceBlue500.opacity(0.05)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("semester", item.plotPosition),
                    y: .value("gpa", item.semester.gpa)
                )
                .interpolationMethod(.linear)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .foregroundStyle(.serviceBlue500)

                PointMark(
                    x: .value("semester", item.plotPosition),
                    y: .value("gpa", item.semester.gpa)
                )
                .symbol {
                    Circle()
                        .fill(.serviceBlue500)
                        .frame(width: 5, height: 5)
                }
            }
        }
        .chartXScale(
            domain: xDomain,
            range: .plotDimension(startPadding: 0, endPadding: 0)
        )
        .chartYScale(domain: 0...4.5)
        .chartYAxis {
            AxisMarks(position: .leading, values: [1.0, 2.0, 3.0, 4.0]) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                    .foregroundStyle(.serviceBlue500.opacity(0.20))
                AxisTick().foregroundStyle(.clear)
                AxisValueLabel {
                    if let axisValue = value.as(Double.self) {
                        Text(String(format: "%.1f", axisValue))
                            .font(.pretendard(13))
                            .foregroundStyle(.serviceGray500)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: displayedSemesters.map(\.plotPosition)) { value in
                AxisTick().foregroundStyle(.clear)
                AxisGridLine().foregroundStyle(.clear)
                AxisValueLabel(
                    anchor: axisLabelAnchor(for: value.as(Double.self)),
                    collisionResolution: .disabled
                ) {
                    if let plotPosition = value.as(Double.self),
                       let item = displayedSemesters.first(where: {
                           $0.plotPosition == plotPosition
                       }) {
                        Text(item.axisLabel)
                            .font(.pretendard(13))
                            .foregroundStyle(.serviceGray500)
                    }
                }
            }
        }
        .frame(height: 166)
    }

    private func axisLabelAnchor(for position: Double?) -> UnitPoint {
        guard let position else { return .top }
        guard displayedSemesters.count > 1 else { return .top }
        if position == displayedSemesters.first?.plotPosition {
            return .topLeading
        }
        if position == displayedSemesters.last?.plotPosition {
            return .topTrailing
        }
        return .top
    }
}

struct ChapelAttendanceCard: View {
    enum Style {
        case compact
        case detailed
    }

    let chapel: ChapelStatus?
    let style: Style

    private let requiredCount = ChapelAttendancePolicy.requiredAttendanceCount
    private let semesterSessionCount = ChapelAttendancePolicy.semesterSessionCount

    private var attendanceGradient: LinearGradient {
        LinearGradient(
            colors: [
                .serviceBlue100,
                .serviceBlue500
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var attendanceCount: Int {
        guard let chapel else { return 0 }
        return ChapelAttendancePolicy.creditedAttendanceCount(
            in: chapel.attendance
        )
    }

    private var remainingToPass: Int {
        max(requiredCount - attendanceCount, 0)
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
                        .foregroundStyle(.black000)
                    Text(L10n.Soomsil.attendanceSummary(attendanceCount, requiredCount))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.serviceBlue500)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.gray600)
            }

            progressBar
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .soomsilCard(cornerRadius: 12)
    }

    private var detailedCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("Pass까지 ")
                    .foregroundStyle(.black000)
                Text("\(remainingToPass)회")
                    .foregroundStyle(.serviceBlue500)
                Text(" 남았어요")
                    .foregroundStyle(.black000)

                Spacer()

                Text("\(attendanceCount)")
                    .font(.pretendard(16, weight: .semibold))
                    .foregroundStyle(.serviceBlue500)
                Text(" / \(semesterSessionCount)")
                    .font(.pretendard(12))
                    .foregroundStyle(.serviceGray500)
            }
            .font(.pretendard(15, weight: .medium))

            homeProgressBar
                .padding(.top, 19)

            Rectangle()
                .fill(.gray100)
                .frame(height: 1)
                .padding(.top, 14)

            HStack(alignment: .firstTextBaseline) {
                Text("좌석 정보")
                    .font(.pretendard(15))
                    .foregroundStyle(.serviceGray500)

                Spacer()

                Text(chapel?.seat ?? "-")
                    .font(.pretendard(16, weight: .semibold))
                    .foregroundStyle(.serviceBlue500)
            }
            .padding(.top, 12)
        }
        .padding(.horizontal, 19)
        .padding(.top, 20)
        .padding(.bottom, 14)
        .frame(maxWidth: .infinity, minHeight: 155)
        .background(.white000)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(attendanceGradient, lineWidth: 1)
                .opacity(0.75)
        }
    }

    private var homeProgressBar: some View {
        VStack(spacing: 3) {
            GeometryReader { proxy in
                Image(systemName: "triangle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 8, height: 6)
                    .rotationEffect(.degrees(180))
                    .foregroundStyle(.serviceBlue500)
                    .offset(
                        x: max(
                            proxy.size.width
                                * CGFloat(requiredCount)
                                / CGFloat(semesterSessionCount) - 4,
                            0
                        )
                    )
            }
            .frame(height: 6)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.serviceGray200)

                    Capsule()
                        .fill(
                            attendanceGradient
                                .shadow(
                                    .inner(
                                        color: .white000.opacity(0.15),
                                        radius: 2,
                                        x: 0.5,
                                        y: 1
                                    )
                                )
                        )
                        .frame(
                            width: proxy.size.width
                                * CGFloat(attendanceCount)
                                / CGFloat(semesterSessionCount)
                        )

                    HStack(spacing: 0) {
                        ForEach(1..<semesterSessionCount, id: \.self) { _ in
                            Spacer(minLength: 0)
                            Rectangle()
                                .fill(.white000.opacity(0.55))
                                .frame(width: 1)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
            .frame(height: 8)
        }
        .frame(height: 17)
        .accessibilityLabel("채플 출석")
        .accessibilityValue("\(attendanceCount) / \(semesterSessionCount)")
    }

    private var progressBar: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.gray100)
                    Capsule()
                        .fill(.serviceBlue600)
                        .frame(
                            width: proxy.size.width * min(
                                CGFloat(attendanceCount) /
                                    CGFloat(requiredCount),
                                1
                            )
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
                .foregroundStyle(.white000.opacity(0.8))
            Text(seatPosition)
                .font(.system(size: 44, weight: .black))
                .foregroundStyle(.white000)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Divider().overlay(.white000.opacity(0.16))
            HStack {
                Text(
                    L10n.Soomsil.chapelSeatDescription(
                        classroom: chapel.classroom,
                        zone: seatZone
                    )
                )
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white000)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer()
                Text(L10n.Soomsil.seatLocation)
                    .font(.system(size: 12, weight: .bold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundStyle(.white000)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.serviceBlue600)
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
        VStack(spacing: 7) {
            shortcutIcon
                .frame(width: 30, height: 30)

            Text(title)
                .font(.pretendard(14, weight: .medium))
                .foregroundStyle(.black000)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 82)
        .background(.white000)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(.gray100, lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    @ViewBuilder
    private var shortcutIcon: some View {
        switch icon {
        case .graduation:
            Image(systemName: "graduationcap")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(.black000)
        case .tuition:
            ZStack {
                Circle()
                    .stroke(.black000, lineWidth: 2)
                    .frame(width: 18, height: 18)
                    .offset(x: -4, y: 4)
                Circle()
                    .stroke(.black000, lineWidth: 2)
                    .frame(width: 18, height: 18)
                    .offset(x: 4, y: -4)
            }
        }
    }
}

struct CourseGradeRow: View {
    let course: CourseGrade

    var body: some View {
        HStack(spacing: 16) {
            Image(gradeAssetName)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .accessibilityLabel(accessibilityGrade)

            VStack(alignment: .leading, spacing: 5) {
                Text(course.title)
                    .font(.pretendard(16, weight: .semibold))
                    .foregroundStyle(.black000)
                    .lineLimit(1)
                Text(courseDetail)
                    .font(.pretendard(14))
                    .foregroundStyle(.serviceGray500)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 100)
    }

    private var gradeAssetName: String {
        recognizedGradeAssetName(in: course.gradePoint)
            ?? recognizedGradeAssetName(in: course.grade)
            ?? "UndefinedGrade"
    }

    private var accessibilityGrade: String {
        let assetName = gradeAssetName
        return assetName == "UndefinedGrade" ? "미정" : assetName
    }

    private var courseDetail: String {
        let credits = course.credits.rounded() == course.credits
            ? String(format: "%.0f", course.credits)
            : String(format: "%.1f", course.credits)
        return "\(course.professor) · \(credits)학점"
    }

    private func recognizedGradeAssetName(in value: String) -> String? {
        let grade = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "＋", with: "+")
            .replacingOccurrences(of: "−", with: "-")
            .replacingOccurrences(of: "–", with: "-")
            .replacingOccurrences(of: "－", with: "-")
            .replacingOccurrences(of: "０", with: "0")

        switch grade {
        case "A+", "A0",
             "B+", "B0",
             "C+", "C0",
             "D+", "D0",
             "F", "P", "NP":
            return grade
        case "A-":
            return "AMinus"
        case "B-":
            return "BMinus"
        case "C-":
            return "CMinus"
        case "D-":
            return "DMinus"
        case "A", "AO":
            return "A0"
        case "B", "BO":
            return "B0"
        case "C", "CO":
            return "C0"
        case "D", "DO":
            return "D0"
        case "PASS", "PASSED", "합격", "급제":
            return "P"
        case "N/P", "N-P", "NONPASS", "NON-PASS", "불합격":
            return "NP"
        default:
            return nil
        }
    }
}

struct SoomsilLoadingOverlay: View {
    let showsDimmedBackground: Bool

    init(showsDimmedBackground: Bool = true) {
        self.showsDimmedBackground = showsDimmedBackground
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(
                    .realBlack.opacity(showsDimmedBackground ? 0.5 : 0)
                )
                .ignoresSafeArea()
                .contentShape(Rectangle())

            ProgressView()
                .controlSize(.large)
                .tint(.serviceBlue600)
        }
    }
}

#Preview("Dashboard components") {
    ScrollView {
        VStack(spacing: 16) {
            StudentInfoCard(profile: MockLMSFixtures.profile)
            GradeOverviewCard(
                cumulativeGPA: MockLMSFixtures.dashboard.cumulativeGPA,
                earnedCredits: MockLMSFixtures.dashboard.cumulativeEarnedCredits,
                semesterRank: MockLMSFixtures.semesters.last?.semesterRank ?? "-",
                totalRank: MockLMSFixtures.semesters.last?.totalRank ?? "-"
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
    .background(.white000)
}
