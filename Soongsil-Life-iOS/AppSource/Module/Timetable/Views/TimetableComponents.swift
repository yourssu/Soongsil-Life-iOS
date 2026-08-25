import SwiftUI

struct TimetableGridView: View {
    let schedule: TimetableSchedule
    let select: (TimetableCourseBlock) -> Void

    var body: some View {
        LazyVStack(spacing: 8) {
            ForEach(schedule.blocks) { block in
                Button {
                    select(block)
                } label: {
                    HStack(spacing: 12) {
                        Text("\(block.weekday.shortName) \(block.period)교시")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.soomsilBlue600)
                            .frame(width: 64, alignment: .leading)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(block.subject)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color.soomsilPrimaryText)
                            Text([block.professor, block.classroom]
                                .filter { !$0.isEmpty }
                                .joined(separator: " · "))
                                .font(.system(size: 13))
                                .foregroundStyle(Color.soomsilSecondaryText)
                        }
                        Spacer()
                    }
                    .padding(16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .soomsilCard()
            }
        }
    }
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
                Button("닫기", action: close)
            }
            detail("시간", block.time)
            detail("담당 교수", block.professor)
            detail("강의실", block.classroom)
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
        ProgressView("시간표를 불러오는 중이에요")
            .frame(maxWidth: .infinity, minHeight: 240)
    }
}

struct TimetableEmptyStateView: View {
    let errorMessage: String?
    let retry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text(errorMessage ?? "표시할 시간표가 없어요")
                .foregroundStyle(Color.soomsilSecondaryText)
            Button("다시 불러오기", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, minHeight: 240)
    }
}
