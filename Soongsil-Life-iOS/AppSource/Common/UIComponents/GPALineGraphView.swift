import Charts
import SwiftUI

struct GPALineGraphView: View {
    struct GPAInfo: Hashable, Identifiable {
        let year: String
        let semester: AcademicSemester
        let gpa: Double

        var id: String {
            "\(year)-\(semester.rawValue)"
        }

        var shortSemester: String {
            let yearDigits = year.filter(\.isNumber)
            let shortYear = yearDigits.isEmpty
                ? year
                : String(yearDigits.suffix(2))

            return "\(shortYear)-\(semester.shortAxisName)"
        }
    }

    private let yAxisValues = [1.5, 3.0, 4.5]
    private let gpaList: [GPAInfo]

    init(gpaList: [GPAInfo]) {
        self.gpaList = gpaList.sorted {
            let lhs = (Int($0.year.filter(\.isNumber)) ?? 0, $0.semester.sortOrder)
            let rhs = (Int($1.year.filter(\.isNumber)) ?? 0, $1.semester.sortOrder)
            return lhs < rhs
        }
    }

    private var latestGPAID: GPAInfo.ID? {
        gpaList.last?.id
    }

    var body: some View {
        Chart {
            ForEach(gpaList) { gpa in
                AreaMark(
                    x: .value(L10n.Grades.semesterSection, gpa.id),
                    yStart: .value(L10n.Soomsil.totalGPA, 1.5),
                    yEnd: .value(L10n.Soomsil.totalGPA, gpa.gpa)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.soomsilBlue600.opacity(0.02),
                            Color.soomsilBlue600.opacity(0.19)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

                LineMark(
                    x: .value(L10n.Grades.semesterSection, gpa.id),
                    y: .value(L10n.Soomsil.totalGPA, gpa.gpa)
                )
                .interpolationMethod(.monotone)
                .lineStyle(StrokeStyle(lineWidth: 2))
                .foregroundStyle(Color.soomsilBlue600)

                PointMark(
                    x: .value(L10n.Grades.semesterSection, gpa.id),
                    y: .value(L10n.Soomsil.totalGPA, gpa.gpa)
                )
                .symbol {
                    Circle()
                        .fill(Color.soomsilBlue600)
                        .frame(width: 10, height: 10)
                        .overlay {
                            Circle()
                                .stroke(.white, lineWidth: 2)
                        }
                }
                .annotation(position: .top, spacing: 2) {
                    Text(gpa.gpa.formattedGPA)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.soomsilBlue600)
                }
            }
        }
        .chartXScale(
            range: .plotDimension(startPadding: -16, endPadding: -16)
        )
        .chartYScale(domain: 1.5...4.5)
        .chartYAxis {
            AxisMarks(position: .leading, values: yAxisValues) { value in
                AxisGridLine()
                    .foregroundStyle(Color.soomsilBorder)
                AxisTick()
                    .foregroundStyle(Color.soomsilBorder)
                AxisValueLabel {
                    if let axisValue = value.as(Double.self) {
                        Text(axisValue.formattedGPA)
                            .font(.system(size: 10))
                            .foregroundStyle(Color.soomsilSecondaryText)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: gpaList.map(\.id)) { value in
                AxisValueLabel {
                    if let semesterID = value.as(String.self),
                       let gpa = gpaList.first(where: { $0.id == semesterID }) {
                        Text(gpa.shortSemester)
                            .font(
                                .system(
                                    size: 11,
                                    weight: semesterID == latestGPAID
                                        ? .semibold
                                        : .medium
                                )
                            )
                            .foregroundStyle(
                                semesterID == latestGPAID
                                    ? Color.soomsilBlue600
                                    : Color.soomsilSecondaryText
                            )
                            .minimumScaleFactor(0.5)
                            .padding(.top, 20)
                    }
                }
            }
        }
        .padding(.top, 16)
        .frame(height: 184)
    }
}

private extension AcademicSemester {
    var shortAxisName: String {
        switch self {
        case .first:
            "1"
        case .summer:
            L10n.Grades.summerAxis
        case .second:
            "2"
        case .winter:
            L10n.Grades.winterAxis
        }
    }
}

private extension Double {
    var formattedGPA: String {
        let roundedToOneDecimal = (self * 10).rounded() / 10
        if abs(self - roundedToOneDecimal) < 0.001 {
            return String(format: "%.1f", self)
        }
        return String(format: "%.2f", self)
    }
}

#Preview("GPA line graph") {
    GPALineGraphView(
        gpaList: [
            .init(year: "2023", semester: .first, gpa: 3.70),
            .init(year: "2023", semester: .second, gpa: 3.50),
            .init(year: "2024", semester: .first, gpa: 4.10),
            .init(year: "2024", semester: .summer, gpa: 4.50),
            .init(year: "2024", semester: .second, gpa: 3.80)
        ]
    )
    .padding(24)
    .background(Color.soomsilSurface)
}
