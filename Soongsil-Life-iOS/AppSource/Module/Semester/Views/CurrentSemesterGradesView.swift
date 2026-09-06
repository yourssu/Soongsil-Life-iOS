import SwiftUI

struct CurrentSemesterGradesView: View {
    let semester: SemesterGrade?
    let courses: [CourseGrade]
    var isLoading = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0) {
                summary
                    .padding(.horizontal, 24)
                    .padding(.top, 34)
                    .padding(.bottom, 30)

                Rectangle()
                    .fill(.gray100)
                    .frame(height: 16)

                if isLoading {
                    ProgressView()
                        .tint(.serviceBlue600)
                        .frame(maxWidth: .infinity, minHeight: 260)
                } else if courses.isEmpty {
                    ContentUnavailableView(
                        L10n.Grades.courseSection,
                        systemImage: "doc.text",
                        description: Text(L10n.Grades.noCurrentCoursesDescription)
                    )
                    .frame(maxWidth: .infinity, minHeight: 260)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(courses) { course in
                            CourseGradeRow(course: course)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .padding(.bottom, 37)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.white000)
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let semester {
                Text(L10n.Grades.semesterTitle(
                    year: semester.year,
                    semester: semester.semester.localizedName
                ))
                .font(.pretendard(14, weight: .semibold))
                .foregroundStyle(.serviceGray500)
                .padding(.bottom, 18)
            }

            Text("평점 평균")
                .font(.pretendard(14, weight: .semibold))
                .foregroundStyle(.black000)
                .padding(.bottom, 6)

            HStack(alignment: .lastTextBaseline, spacing: 5) {
                Text(String(format: "%.2f", semester?.gpa ?? courseAverage))
                    .font(.pretendard(34, weight: .bold))
                    .foregroundStyle(.serviceBlue500)
                Text("/ 4.50")
                    .font(.pretendard(14, weight: .medium))
                    .foregroundStyle(.serviceGray500)
            }
            .padding(.bottom, 25)

            VStack(spacing: 18) {
                metric(
                    title: L10n.Soomsil.earnedCredits,
                    value: formattedCredits(semester?.earnedCredits ?? totalCredits),
                    total: semester.map { formattedCredits($0.attemptedCredits) }
                )

                if let semester {
                    metric(title: "학기별 석차", rank: semester.semesterRank)
                    metric(title: "전체 석차", rank: semester.totalRank)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func metric(
        title: String,
        value: String,
        total: String? = nil
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.pretendard(14))
                .foregroundStyle(.serviceGray500)

            Spacer(minLength: 12)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(.pretendard(16, weight: .semibold))
                    .foregroundStyle(.black000)
                if let total {
                    Text("/ \(total)")
                        .font(.pretendard(12))
                        .foregroundStyle(.serviceGray500)
                }
            }
        }
    }

    private func metric(title: String, rank: String) -> some View {
        let values = rank
            .split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false)
            .map(String.init)

        return metric(
            title: title,
            value: values.first?.trimmingCharacters(in: .whitespaces) ?? "-",
            total: values.count > 1
                ? values[1].trimmingCharacters(in: .whitespaces)
                : "-"
        )
    }

    private var totalCredits: Double {
        courses.reduce(0) { $0 + $1.credits }
    }

    private var courseAverage: Double {
        let values = courses.compactMap { Double($0.gradePoint) }
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    private func formattedCredits(_ value: Double) -> String {
        value.rounded() == value
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}

#Preview("Current semester grades") {
    CurrentSemesterGradesView(
        semester: MockLMSFixtures.semesters.last,
        courses: MockLMSFixtures.courses
    )
}
