import SwiftUI

struct TimetableGridView: View {
    let schedule: TimetableSchedule
    let select: (TimetableCourseBlock) -> Void

    private let timeColumnWidth: CGFloat = 42
    private let columnSpacing: CGFloat = 3
    private let hourHeight: CGFloat = 38
    private let headerHeight: CGFloat = 30

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
        .padding(.horizontal, 10)
        .padding(.vertical, 14)
        .soomsilCard(cornerRadius: 16)
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
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.soomsilSecondaryText)
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
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.soomsilSecondaryText)
                    .frame(width: timeColumnWidth, alignment: .leading)
                    .offset(y: yOffset(for: minutes) - 5)
            }

            ForEach(schedule.blocks) { block in
                if let weekdayIndex = weekdays.firstIndex(of: block.weekday) {
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
                    .font(.system(size: 9, weight: .bold))
                    .lineLimit(2)

                if !block.classroom.isEmpty {
                    Text(block.classroom)
                        .font(.system(size: 8, weight: .medium))
                        .lineLimit(2)
                }
            }
            .minimumScaleFactor(0.75)
            .foregroundStyle(style.foreground)
            .padding(5)
            .frame(
                width: width,
                height: height,
                alignment: .topLeading
            )
            .background(style.background)
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
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
        CGFloat(schedule.endMinutes - schedule.startMinutes) / 60 * hourHeight
    }

    private var hourMarks: [Int] {
        Array(stride(
            from: schedule.startMinutes,
            to: schedule.endMinutes,
            by: 60
        ))
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
        CGFloat(minutes - schedule.startMinutes) / 60 * hourHeight
    }

    private func blockHeight(_ block: TimetableCourseBlock) -> CGFloat {
        max(
            CGFloat(block.endMinutes - block.startMinutes) / 60 * hourHeight - 2,
            30
        )
    }

    private func hourText(_ minutes: Int) -> String {
        "\(minutes / 60):00"
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
            background: Color.soomsilBlue100,
            foreground: Color.soomsilBlue600
        ),
        CourseStyle(
            background: Color.soomsilGreen50,
            foreground: Color.soomsilGreen500
        ),
        CourseStyle(
            background: Color(red: 0.94, green: 0.88, blue: 1),
            foreground: Color(red: 0.50, green: 0.16, blue: 0.78)
        ),
        CourseStyle(
            background: Color("pointColor100"),
            foreground: Color("logoViolet")
        ),
        CourseStyle(
            background: Color.soomsilRed50,
            foreground: Color.soomsilRed500
        )
    ]
}

struct TimetableCourseDetailSheet: View {
    let block: TimetableCourseBlock
    let close: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(block.subject)
                    .font(.system(size: 22, weight: .bold))
                Spacer()
                Button(L10n.Timetable.close, action: close)
            }
            detail(L10n.Timetable.time, block.time)
            detail(L10n.Timetable.professor, block.professor)
            detail(L10n.Timetable.classroom, block.classroom)
            Spacer()
        }
        .padding(24)
    }

    private func detail(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .foregroundStyle(Color.soomsilSecondaryText)
                .frame(width: 72, alignment: .leading)
            Text(value.isEmpty ? "-" : value)
                .foregroundStyle(Color.soomsilPrimaryText)
        }
    }
}

struct TimetableLoadingView: View {
    var body: some View {
        ProgressView(L10n.Timetable.loading)
            .frame(maxWidth: .infinity, minHeight: 240)
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
