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

    private struct PlotPoint: Identifiable {
        let position: Double
        let gpa: GPAInfo

        var id: GPAInfo.ID { gpa.id }
    }

    private let yAxisValues = [1.0, 2.0, 3.0, 4.0]
    private let gpaList: [GPAInfo]
    private let highlightedGPAID: GPAInfo.ID?

    private var plotPoints: [PlotPoint] {
        gpaList.enumerated().map { index, gpa in
            PlotPoint(position: Double(index), gpa: gpa)
        }
    }

    private var xDomain: ClosedRange<Double> {
        guard plotPoints.count > 1 else {
            return -0.5...0.5
        }
        return 0...Double(plotPoints.count - 1)
    }

    init(
        gpaList: [GPAInfo],
        highlightedGPAID: GPAInfo.ID? = nil
    ) {
        let sortedGPAList = gpaList.sorted {
            let lhs = (Int($0.year.filter(\.isNumber)) ?? 0, $0.semester.sortOrder)
            let rhs = (Int($1.year.filter(\.isNumber)) ?? 0, $1.semester.sortOrder)
            return lhs < rhs
        }
        self.gpaList = Array(sortedGPAList.suffix(8))
        self.highlightedGPAID = highlightedGPAID ?? sortedGPAList.last?.id
    }

    var body: some View {
        Chart {
            ForEach(plotPoints) { point in
                AreaMark(
                    x: .value(L10n.Grades.semesterSection, point.position),
                    yStart: .value(L10n.Soomsil.totalGPA, 0),
                    yEnd: .value(L10n.Soomsil.totalGPA, point.gpa.gpa)
                )
                .interpolationMethod(.linear)
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            .serviceBlue500.opacity(0.24),
                            .serviceBlue500.opacity(0.03)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value(L10n.Grades.semesterSection, point.position),
                    y: .value(L10n.Soomsil.totalGPA, point.gpa.gpa)
                )
                .interpolationMethod(.linear)
                .lineStyle(StrokeStyle(lineWidth: 2.5))
                .foregroundStyle(.serviceBlue500)

                PointMark(
                    x: .value(L10n.Grades.semesterSection, point.position),
                    y: .value(L10n.Soomsil.totalGPA, point.gpa.gpa)
                )
                .symbol {
                    Circle()
                        .fill(.serviceBlue500)
                        .frame(
                            width: point.id == highlightedGPAID ? 12 : 7,
                            height: point.id == highlightedGPAID ? 12 : 7
                        )
                        .overlay {
                            if point.id == highlightedGPAID {
                                Circle()
                                    .stroke(.white000, lineWidth: 2.5)
                            }
                        }
                }
                .annotation(
                    position: .top,
                    alignment: annotationAlignment(for: point),
                    spacing: 4
                ) {
                    if point.id == highlightedGPAID {
                        GPAValueBubble(value: point.gpa.gpa.formattedGPA)
                    }
                }
            }
        }
        .chartXScale(
            domain: xDomain,
            range: .plotDimension(startPadding: 0, endPadding: 0)
        )
        .chartYScale(domain: 0...4.5)
        .chartYAxis {
            AxisMarks(position: .leading, values: yAxisValues) { value in
                AxisGridLine()
                    .foregroundStyle(.serviceBlue500.opacity(0.2))
                AxisTick()
                    .foregroundStyle(.clear)
                AxisValueLabel {
                    if let axisValue = value.as(Double.self) {
                        Text(axisValue.formattedGPA)
                            .font(.pretendard(12))
                            .foregroundStyle(.serviceGray500)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: plotPoints.map(\.position)) { value in
                AxisGridLine()
                    .foregroundStyle(.clear)
                AxisTick()
                    .foregroundStyle(.clear)
                AxisValueLabel(
                    anchor: axisLabelAnchor(for: value.as(Double.self)),
                    collisionResolution: .disabled
                ) {
                    if let position = value.as(Double.self),
                       let point = plotPoint(at: position) {
                        Text(axisLabel(for: point.gpa))
                            .font(.pretendard(12))
                            .foregroundStyle(.serviceGray500)
                            .minimumScaleFactor(0.5)
                            .padding(.top, 12)
                    }
                }
            }
        }
        // The value bubble sits above the selected point. Reserve its full
        // height so a GPA near 4.5 never escapes into the rank summary.
        .padding(.top, 48)
        .frame(height: 214)
    }

    private func plotPoint(at position: Double) -> PlotPoint? {
        plotPoints.first { $0.position == position }
    }

    private func annotationAlignment(for point: PlotPoint) -> Alignment {
        if point.position == plotPoints.first?.position {
            return .leading
        }
        if point.position == plotPoints.last?.position {
            return .trailing
        }
        return .center
    }

    private func axisLabelAnchor(for position: Double?) -> UnitPoint {
        guard let position else { return .top }
        if position == plotPoints.first?.position {
            return .topLeading
        }
        if position == plotPoints.last?.position {
            return .topTrailing
        }
        return .top
    }

    private func axisLabel(for gpa: GPAInfo) -> String {
        guard let index = gpaList.firstIndex(of: gpa) else {
            return gpa.shortSemester
        }
        return "\(index / 2 + 1)-\(index % 2 + 1)"
    }
}

private struct GPAValueBubble: View {
    let value: String

    var body: some View {
        VStack(spacing: -1) {
            Text(value)
                .font(.pretendard(12, weight: .semibold))
                .foregroundStyle(.serviceBlue500)
                .padding(.horizontal, 10)
                .frame(height: 31)
                .background(.serviceGray200)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

            GPAValueBubbleTip()
                .fill(.serviceGray200)
                .frame(width: 12, height: 7)
        }
    }
}

private struct GPAValueBubbleTip: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.closeSubpath()
        }
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
    .background(.white000)
}
