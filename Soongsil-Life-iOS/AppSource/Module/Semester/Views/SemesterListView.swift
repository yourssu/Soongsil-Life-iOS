import SwiftUI

struct SemesterListView: View {
    @State var viewModel: SemesterViewModel

    private let graduationCredits = 133

    private var selectedSemester: SemesterGrade? {
        viewModel.output.selectedSemester
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            if viewModel.output.semesters.isEmpty {
                ContentUnavailableView(
                    L10n.Grades.noSemesterGrades,
                    systemImage: "chart.line.downtrend.xyaxis",
                    description: Text(L10n.Grades.noSemesterGradesDescription)
                )
                .frame(maxWidth: .infinity, minHeight: 520)
            } else if let selectedSemester {
                LazyVStack(spacing: 0) {
                    semesterTabs
                        .padding(.top, 8)
                        .padding(.bottom, 25)

                    gradeSummary(selectedSemester)
                        .padding(.horizontal, 24)

                    GPALineGraphView(
                        gpaList: visibleGPAList,
                        highlightedGPAID: selectedSemester.id
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 4)
                    .padding(.bottom, 24)

                    Rectangle()
                        .fill(.gray100)
                        .frame(height: 16)

                    coursesContent
                        .padding(.horizontal, 20)
                        .padding(.top, 9)
                        .padding(.bottom, 37)
                }
            }
        }
        .background(.white000)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarRole(.editor)
        .tint(.black000)
        .toolbar(.visible, for: .navigationBar)
        .task {
            guard let selectedSemesterID = viewModel.output.selectedSemesterID else {
                return
            }
            await viewModel.transform(
                input: .selectSemester(selectedSemesterID)
            )
        }
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
                        .font(.pretendard(13, weight: .semibold))
                        .foregroundStyle(
                            selected ? .serviceBlue600 : .serviceGray500
                        )
                        .padding(.horizontal, 16)
                        .frame(height: 32)
                        .background {
                            Capsule()
                                .fill(selected ? .white000 : .gray100)
                        }
                        .overlay {
                            if selected {
                                Capsule()
                                    .strokeBorder(.serviceBlue600, lineWidth: 1)
                            }
                        }
                        .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func gradeSummary(_ semester: SemesterGrade) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("평점 평균")
                .font(.pretendard(14, weight: .semibold))
                .foregroundStyle(.black000)
                .padding(.bottom, 6)

            HStack(alignment: .lastTextBaseline, spacing: 5) {
                Text(String(format: "%.2f", semester.gpa))
                    .font(.pretendard(34, weight: .bold))
                    .foregroundStyle(.serviceBlue500)

                Text("/ 4.50")
                    .font(.pretendard(14, weight: .medium))
                    .foregroundStyle(.serviceGray500)
            }
            .padding(.bottom, 25)

            VStack(spacing: 18) {
                gradeMetric(
                    title: L10n.Soomsil.earnedCredits,
                    primaryValue: formattedNumber(cumulativeEarnedCredits),
                    secondaryValue: "\(graduationCredits)"
                )
                gradeMetric(
                    title: "학기별 석차",
                    rank: semester.semesterRank
                )
                gradeMetric(
                    title: "전체 석차",
                    rank: semester.totalRank
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func gradeMetric(
        title: String,
        primaryValue: String,
        secondaryValue: String
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.pretendard(14))
                .foregroundStyle(.serviceGray500)

            Spacer(minLength: 12)

            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(primaryValue)
                    .font(.pretendard(16, weight: .semibold))
                    .foregroundStyle(.black000)
                Text("/ \(secondaryValue)")
                    .font(.pretendard(12))
                    .foregroundStyle(.serviceGray500)
            }
        }
    }

    private func gradeMetric(title: String, rank: String) -> some View {
        let values = rank
            .split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false)
            .map(String.init)

        return gradeMetric(
            title: title,
            primaryValue: values.first?.trimmingCharacters(in: .whitespaces) ?? "-",
            secondaryValue: values.count > 1
                ? values[1].trimmingCharacters(in: .whitespaces)
                : "-"
        )
    }

    @ViewBuilder
    private var coursesContent: some View {
        if viewModel.output.isLoadingSelectedSemester {
            ProgressView()
                .tint(.serviceBlue600)
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
            LazyVStack(spacing: 0) {
                ForEach(viewModel.output.selectedCourses) { course in
                    CourseGradeRow(course: course)
                }
            }
        }
    }

    private var visibleGPAList: [GPALineGraphView.GPAInfo] {
        viewModel.output.semesters
            .filter {
                $0.gpa > 0
                    && ($0.semester == .first || $0.semester == .second)
            }
            .map {
                GPALineGraphView.GPAInfo(
                    year: $0.year,
                    semester: $0.semester,
                    gpa: $0.gpa
                )
            }
    }

    private var cumulativeEarnedCredits: Double {
        viewModel.output.semesters.reduce(0) { $0 + $1.earnedCredits }
    }

    private func formattedNumber(_ value: Double) -> String {
        value.rounded() == value
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }

    private func errorCard(_ message: String) -> some View {
        VStack(spacing: 12) {
            Text(message)
                .font(.pretendard(13, weight: .medium))
                .foregroundStyle(.serviceGray500)
                .multilineTextAlignment(.center)
            Button(L10n.Common.retry) {
                Task {
                    await viewModel.transform(input: .reloadSelectedSemester)
                }
            }
            .font(.pretendard(13, weight: .bold))
            .foregroundStyle(.serviceBlue600)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
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
