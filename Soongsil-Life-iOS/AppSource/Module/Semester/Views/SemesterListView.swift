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
                semesterTabs

                if let selectedSemester {
                    summaryCard(selectedSemester)
                    trendCard

                    if viewModel.output.isLoadingSelectedSemester {
                        ProgressView()
                            .tint(Color.soomsilBlue600)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                    } else if let errorMessage = viewModel.output.errorMessage {
                        errorCard(errorMessage)
                    } else if viewModel.output.selectedCourses.isEmpty {
                        ContentUnavailableView(
                            L10n.Grades.courseSection,
                            systemImage: "doc.text",
                            description: Text(L10n.Home.retryDescription)
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
        .background(Color.soomsilBackground)
        .navigationTitle(L10n.Grades.title)
        .navigationBarTitleDisplayMode(.inline)
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
                        .foregroundStyle(selected ? .white : Color.soomsilSecondaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(selected ? Color.soomsilGray950 : Color.soomsilMutedSurface)
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
                .foregroundStyle(Color.soomsilGray500)
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(String(format: "%.2f", semester.gpa))
                    .font(.system(size: 40, weight: .black))
                    .foregroundStyle(.white)
                Text("/ 4.5")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(Color.soomsilGray500)
            }
            Text(L10n.Grades.semesterDetail(
                credits: semester.earnedCredits,
                rank: semester.semesterRank
            ))
            .font(.system(size: 13))
            .foregroundStyle(Color.soomsilGray500)
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
                    .foregroundStyle(Color.soomsilPrimaryText)

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
                            ? Color.soomsilBlue600
                            : Color.soomsilSlate400
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
                .foregroundStyle(Color.soomsilSecondaryText)
                .multilineTextAlignment(.center)
            Button(L10n.Home.retryDescription) {
                Task {
                    await viewModel.transform(input: .reloadSelectedSemester)
                }
            }
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Color.soomsilBlue600)
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
