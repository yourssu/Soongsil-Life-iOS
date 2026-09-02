import SwiftUI

struct SemesterListView: View {
    @State var viewModel: SemesterViewModel
    @State private var includesSeasonalSemesters = false

    private var selectedSemester: SemesterGrade? {
        viewModel.output.selectedSemester
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 14) {
                if viewModel.output.semesters.isEmpty {
                    ContentUnavailableView(
                        L10n.Grades.noSemesterGrades,
                        systemImage: "chart.line.downtrend.xyaxis",
                        description: Text(L10n.Grades.noSemesterGradesDescription)
                    )
                    .frame(maxWidth: .infinity, minHeight: 320)
                } else {
                    semesterTabs
                }

                if !viewModel.output.semesters.isEmpty,
                   let selectedSemester {
                    summaryCard(selectedSemester)
                    trendCard

                    if viewModel.output.isLoadingSelectedSemester {
                        ProgressView()
                            .tint(.pointColor600)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                    } else if let errorMessage = viewModel.output.errorMessage {
                        errorCard(errorMessage)
                    } else if viewModel.output.selectedCourses.isEmpty {
                        ContentUnavailableView(
                            L10n.Grades.courseSection,
                            systemImage: "doc.text",
                            description: Text(L10n.Grades.noCoursesDescription)
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                    } else {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.output.selectedCourses) { course in
                                CourseGradeRow(course: course)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
        .background(.white000)
        .soomsilDetailNavigation(title: L10n.Grades.title)
    }

    private var semesterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.output.semesters.reversed()) { semester in
                    let selected = selectedSemester?.id == semester.id
                    Button {
                        Task {
                            await viewModel.transform(
                                input: .selectSemester(semester.id)
                            )
                        }
                    } label: {
                        Text(L10n.Grades.semesterTitle(
                            year: semester.year,
                            semester: semester.semester.localizedName
                        ))
                        .font(.system(size: 13, weight: selected ? .bold : .medium))
                        .foregroundStyle(selected ? .white : .gray600)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(selected ? .black000 : .gray050)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func summaryCard(_ semester: SemesterGrade) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Soomsil.totalGPA)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.gray500)
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(String(format: "%.2f", semester.gpa))
                    .font(.system(size: 40, weight: .black))
                    .foregroundStyle(.white)
                Text("/ 4.5")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(.gray500)
            }
            Text(L10n.Grades.semesterDetail(
                credits: semester.earnedCredits,
                rank: semester.semesterRank
            ))
            .font(.system(size: 13))
            .foregroundStyle(.gray500)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 16)
        .background(.black)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(L10n.Soomsil.gpaTrend)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.black000)

                Spacer()

                Button {
                    includesSeasonalSemesters.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(
                            systemName: includesSeasonalSemesters
                                ? "checkmark.circle.fill"
                                : "circle"
                        )
                        .font(.system(size: 16, weight: .medium))

                        Text(L10n.Grades.includeSeasonalSemesters)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(
                        includesSeasonalSemesters
                            ? .pointColor600
                            : .gray600
                    )
                }
                .buttonStyle(.plain)
            }

            GPALineGraphView(gpaList: visibleGPAList)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .soomsilCard(cornerRadius: 20)
    }

    private var visibleGPAList: [GPALineGraphView.GPAInfo] {
        viewModel.output.semesters
            .filter { $0.gpa > 0 }
            .filter {
                includesSeasonalSemesters
                    || ($0.semester != .summer && $0.semester != .winter)
            }
            .map {
                GPALineGraphView.GPAInfo(
                    year: $0.year,
                    semester: $0.semester,
                    gpa: $0.gpa
                )
            }
    }

    private func errorCard(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.gray600)
                .multilineTextAlignment(.center)
            Button(L10n.Common.retry) {
                Task {
                    await viewModel.transform(input: .reloadSelectedSemester)
                }
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(.pointColor600)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .soomsilCard(cornerRadius: 16)
    }
}

#Preview("Semester grades") {
    let container = DIContainer.preview
    NavigationStack {
        SemesterListView(
            viewModel: SemesterViewModel(
                repository: container.gradeRepository,
                semesters: MockLMSFixtures.semesters,
                initialCourses: MockLMSFixtures.courses
            )
        )
    }
}
