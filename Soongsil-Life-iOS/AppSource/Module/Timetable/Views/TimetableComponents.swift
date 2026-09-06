import SwiftUI

struct TimetableGridView: View {
    let schedule: TimetableSchedule
    let select: (TimetableCourseBlock) -> Void

    private let timeColumnWidth: CGFloat = 30
    private let columnSpacing: CGFloat = 2
    private let hourHeight: CGFloat = 43
    private let headerHeight: CGFloat = 35
    private let minimumMinute = 0
    private let maximumMinute = 24 * 60

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { proxy in
                weekdayHeader(width: proxy.size.width)
            }
            .frame(height: headerHeight)

            GeometryReader { proxy in
                timeline(width: proxy.size.width)
            }
            .frame(height: timelineHeight)
        }
        .background(.white000)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.gray100, lineWidth: 1)
        }
    }

    private func weekdayHeader(width: CGFloat) -> some View {
        let weekdays = schedule.visibleWeekdays
        let dayWidth = dayColumnWidth(
            totalWidth: width,
            weekdayCount: weekdays.count
        )

        return HStack(spacing: columnSpacing) {
            Color.clear
                .frame(width: timeColumnWidth)

            ForEach(weekdays, id: \.self) { weekday in
                Text(weekday.shortName)
                    .font(.pretendard(10, weight: .medium))
                    .foregroundStyle(.serviceGray500)
                    .frame(width: dayWidth)
            }
        }
    }

    private func timeline(width: CGFloat) -> some View {
        let weekdays = schedule.visibleWeekdays
        let dayWidth = dayColumnWidth(
            totalWidth: width,
            weekdayCount: weekdays.count
        )

        return ZStack(alignment: .topLeading) {
            ForEach(hourMarks, id: \.self) { minutes in
                Text(hourText(minutes))
                    .font(.pretendard(10, weight: .medium))
                    .foregroundStyle(.serviceGray500)
                    .frame(width: timeColumnWidth, alignment: .center)
                    .offset(y: yOffset(for: minutes) - 5)
            }

            ForEach(schedule.blocks) { block in
                if isRenderable(block),
                   let weekdayIndex = weekdays.firstIndex(of: block.weekday) {
                    courseButton(
                        block,
                        width: dayWidth,
                        height: blockHeight(block)
                    )
                    .offset(
                        x: timeColumnWidth
                            + columnSpacing
                            + CGFloat(weekdayIndex) * (dayWidth + columnSpacing),
                        y: yOffset(for: block.startMinutes)
                    )
                }
            }
        }
    }

    private func courseButton(
        _ block: TimetableCourseBlock,
        width: CGFloat,
        height: CGFloat
    ) -> some View {
        let style = courseStyle(for: block.subject)

        return Button {
            select(block)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(block.subject)
                    .font(.pretendard(9, weight: .semibold))
                    .lineLimit(2)

                if !block.classroom.isEmpty {
                    Text(block.classroom)
                        .font(.pretendard(8, weight: .medium))
                        .lineLimit(2)
                }
            }
            .minimumScaleFactor(0.75)
            .foregroundStyle(style.foreground)
            .padding(.horizontal, 4)
            .padding(.vertical, 5)
            .frame(
                width: width,
                height: height,
                alignment: .topLeading
            )
            .background(style.background)
            .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            [block.subject, block.classroom, block.time]
                .filter { !$0.isEmpty }
                .joined(separator: ", ")
        )
    }

    private var timelineHeight: CGFloat {
        CGFloat(displayEndMinutes - displayStartMinutes) / 60 * hourHeight
    }

    private var hourMarks: [Int] {
        Array(stride(
            from: displayStartMinutes,
            to: displayEndMinutes,
            by: 60
        ))
    }

    private var displayStartMinutes: Int {
        min(max(schedule.startMinutes, minimumMinute), maximumMinute)
    }

    private var displayEndMinutes: Int {
        let lastCourse = schedule.blocks.map(\.endMinutes).max() ?? 22 * 60
        let boundedLastCourse = min(max(lastCourse, minimumMinute), maximumMinute)
        let roundedLastCourse = min(
            ((boundedLastCourse + 59) / 60) * 60,
            maximumMinute
        )
        return max(22 * 60, roundedLastCourse)
    }

    private func dayColumnWidth(
        totalWidth: CGFloat,
        weekdayCount: Int
    ) -> CGFloat {
        guard weekdayCount > 0 else { return 0 }
        let totalSpacing = columnSpacing * CGFloat(weekdayCount)
        return max(
            (totalWidth - timeColumnWidth - totalSpacing)
                / CGFloat(weekdayCount),
            0
        )
    }

    private func yOffset(for minutes: Int) -> CGFloat {
        let boundedMinutes = min(max(minutes, displayStartMinutes), displayEndMinutes)
        return CGFloat(boundedMinutes - displayStartMinutes) / 60 * hourHeight
    }

    private func blockHeight(_ block: TimetableCourseBlock) -> CGFloat {
        let boundedStart = min(max(block.startMinutes, minimumMinute), maximumMinute)
        let boundedEnd = min(max(block.endMinutes, boundedStart), maximumMinute)
        return max(
            CGFloat(boundedEnd - boundedStart) / 60 * hourHeight - 2,
            30
        )
    }

    private func isRenderable(_ block: TimetableCourseBlock) -> Bool {
        (minimumMinute..<maximumMinute).contains(block.startMinutes)
            && (1...maximumMinute).contains(block.endMinutes)
            && block.endMinutes > block.startMinutes
    }

    private func hourText(_ minutes: Int) -> String {
        "\(minutes / 60)"
    }

    private func courseStyle(for subject: String) -> CourseStyle {
        let subjects = schedule.blocks.reduce(into: [String]()) { result, block in
            if !result.contains(block.subject) {
                result.append(block.subject)
            }
        }
        let index = subjects.firstIndex(of: subject) ?? 0
        return CourseStyle.palette[index % CourseStyle.palette.count]
    }
}

private struct CourseStyle {
    let background: Color
    let foreground: Color

    static let palette: [CourseStyle] = [
        CourseStyle(
            background: .serviceBlue500.opacity(0.12),
            foreground: .logoIndigo
        ),
        CourseStyle(
            background: .serviceBlue500.opacity(0.10),
            foreground: .logoViolet
        ),
        CourseStyle(
            background: .gray100,
            foreground: .serviceGray500
        ),
        CourseStyle(
            background: .logoYellow.opacity(0.22),
            foreground: .gray700
        ),
        CourseStyle(
            background: .warningRed050,
            foreground: .warningRed500
        )
    ]
}

struct TimetableCourseDetailSheet: View {
    let block: TimetableCourseBlock
    let close: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(block.subject)
                .font(.pretendard(18, weight: .semibold))
                .foregroundStyle(.black000)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)

            Text(professorTitle)
                .font(.pretendard(13))
                .foregroundStyle(.serviceGray500)
                .padding(.top, 8)

            VStack(spacing: 0) {
                detail("요일", block.weekday.fullName)
                detail(L10n.Timetable.time, block.time)
                detail(L10n.Timetable.classroom, block.classroom)
            }
            .padding(.top, 10)

            Spacer()

            Button(action: close) {
                Text(L10n.Timetable.close)
                    .font(.pretendard(14, weight: .semibold))
                    .foregroundStyle(.black000)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 40)
        .padding(.bottom, 4)
    }

    private func detail(_ title: String, _ value: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .font(.pretendard(13))
                .foregroundStyle(.serviceGray500)

            Spacer(minLength: 16)

            Text(value.isEmpty ? "-" : value)
                .font(.pretendard(14, weight: .medium))
                .foregroundStyle(.black000)
                .multilineTextAlignment(.trailing)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(height: 44)
    }

    private var professorTitle: String {
        guard !block.professor.isEmpty else { return "-" }
        return block.professor.hasSuffix("교수")
            ? block.professor
            : "\(block.professor) 교수"
    }
}

struct TimetableLoadingView: View {
    var body: some View {
        ProgressView(L10n.Timetable.loading)
            .tint(.serviceBlue600)
            .foregroundStyle(.serviceGray500)
            .frame(maxWidth: .infinity, minHeight: 240)
    }
}

private extension TimetableWeekday {
    var fullName: String {
        switch self {
        case .monday: "월요일"
        case .tuesday: "화요일"
        case .wednesday: "수요일"
        case .thursday: "목요일"
        case .friday: "금요일"
        case .saturday: "토요일"
        case .sunday: "일요일"
        }
    }
}

struct TimetableEmptyStateView: View {
    var body: some View {
        ContentUnavailableView {
            Label(L10n.Timetable.empty, systemImage: "calendar.badge.minus")
        } description: {
            Text(L10n.Timetable.emptyDescription)
        }
        .frame(maxWidth: .infinity, minHeight: 240)
    }
}

struct TimetableErrorStateView: View {
    let errorMessage: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(
                L10n.Timetable.loadFailed,
                systemImage: "wifi.exclamationmark"
            )
        } description: {
            Text(errorMessage)
        } actions: {
            Button(L10n.Common.retry, action: retry)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, minHeight: 240)
    }
}
