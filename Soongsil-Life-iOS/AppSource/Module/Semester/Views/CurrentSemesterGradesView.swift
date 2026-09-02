import SwiftUI

struct CurrentSemesterGradesView: View {
    let semester: SemesterGrade?
    let courses: [CourseGrade]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            summary
                .padding(.bottom, 32)

            if courses.isEmpty {
                ContentUnavailableView(
                    L10n.Grades.courseSection,
                    systemImage: "doc.text",
                    description: Text(L10n.Grades.noCurrentCoursesDescription)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 8) {
                        ForEach(courses) { course in
                            CourseGradeRow(course: course)
                        }
                    }
                    .padding(.bottom, 37)
                }
            }
        }
        .padding(.top, 48)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.white000)
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(semester.map {
                L10n.Grades.semesterTitle(
                    year: $0.year,
                    semester: $0.semester.localizedName
                )
            } ?? L10n.Soomsil.currentSemesterGrades)
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(.black000)
            .padding(.bottom, 4)

            Text(L10n.Soomsil.currentSemesterGrades)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.gray600)
                .padding(.bottom, 20)

            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.Soomsil.totalGPA)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.gray600)
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(String(format: "%.2f", semester?.gpa ?? courseAverage))
                            .font(.system(size: 32, weight: .black))
                            .foregroundStyle(.black000)
                        Text("/ 4.5")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.gray600)
                    }
                }
                Spacer()
                metric(
                    title: L10n.Soomsil.earnedCredits,
                    value: String(format: "%.1f", semester?.earnedCredits ?? totalCredits)
                )
                metric(
                    title: L10n.Soomsil.courses,
                    value: "\(courses.count)"
                )
            }
        }
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.gray600)
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.black000)
        }
        .padding(.leading, 20)
    }

    private var totalCredits: Double {
        courses.reduce(0) { $0 + $1.credits }
    }

    private var courseAverage: Double {
        let values = courses.compactMap { Double($0.gradePoint) }
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
}

#Preview("Current semester grades") {
    CurrentSemesterGradesView(
        semester: MockLMSFixtures.semesters.last,
        courses: MockLMSFixtures.courses
    )
}
