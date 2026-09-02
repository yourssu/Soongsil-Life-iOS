import SwiftUI

struct TuitionView: View {
    @State var viewModel: TuitionViewModel // ViewModel 설정
    @Namespace private var segmentedControlNamespace

    private let segmentAnimation = Animation.spring(
        response: 0.25,
        dampingFraction: 0.85
    )

    var body: some View {
        VStack(spacing: 0) {
            // 로딩 중이거나 데이터 없음녀 ProgessView 표시
            if (!viewModel.output.hasLoaded || viewModel.output.isLoading)
                && !viewModel.output.hasLoadedData {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.output.errorMessage,
                      !viewModel.output.hasLoadedData {
                ContentUnavailableView {
                    Label(
                        L10n.Tuition.loadFailed,
                        systemImage: "wifi.exclamationmark"
                    )
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button(L10n.Common.retry) {
                        Task {
                            await viewModel.transform(input: .load(force: true))
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // 실제 데이터 영역
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 11) {
                        // 위에 Bar
                        segmentedControl
                        // 카드
                        content
                            .id(viewModel.output.selectedTab)
                            .transition(.opacity)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    .animation(segmentAnimation, value: viewModel.output.selectedTab)
                }
                // 아래로 당겨 API 재요청 가능
                .refreshable {
                    await viewModel.transform(input: .load(force: true))
                }
            }
        }
        .background(.white000)
        .soomsilDetailNavigation(title: L10n.Home.tuitionScholarship)
        .task {
            await viewModel.transform(input: .load()) // 화면 실행 시 바로 데이터 불러오기 (비동기)
        }
        // 에러 발생 시 알람창
        .alert(L10n.Home.tuitionScholarship, isPresented: showsError) {
            // 에러 확인 버튼
            Button(L10n.Common.confirm, role: .cancel) {
                Task {
                    // 에러 메세지 지우기
                    await viewModel.transform(input: .errorDismissed)
                }
            }
            // 재시도 버튼
            Button(L10n.Tuition.retry) {
                Task {
                    // 데이터 재요청
                    await viewModel.transform(input: .load(force: true))
                }
            }
        } message: {
            Text(viewModel.output.errorMessage ?? "")
        }
    }
    // errorMessage 값을 보고 alert 표시 여부 계산
    private var showsError: Binding<Bool> {
        Binding(
            get: {
                viewModel.output.errorMessage != nil
                    && viewModel.output.hasLoadedData
            },
            set: { isPresented in
                guard !isPresented else { return }
                Task {
                    await viewModel.transform(input: .errorDismissed)
                }
            }
        )
    }

    // 세그먼트 탭
    private var segmentedControl: some View {
        HStack(spacing: 4) {
            ForEach(TuitionViewModel.Tab.allCases, id: \.self) { tab in
                let isSelected = viewModel.output.selectedTab == tab
                Button {
                    Task {
                        await viewModel.transform(input: .selectTab(tab))
                    }
                } label: {
                    ZStack {
                        if isSelected {
                            Capsule()
                                .fill(.pointColor600)
                                .matchedGeometryEffect(
                                    id: "selectedSegment",
                                    in: segmentedControlNamespace
                                )
                        }

                        Text(tab.title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(
                                isSelected ? Color.white : .gray600
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 35.5)
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .frame(height: 43.5)
        .frame(maxWidth: .infinity)
        .frame(maxWidth: 362)
        .background(.gray050)
        .clipShape(Capsule())
    }

    @ViewBuilder 
    // 카드 부분
    private var content: some View {
        switch viewModel.output.selectedTab {
        case .tuition:
            if viewModel.output.tuitionRecords.isEmpty {
                emptyState(L10n.Tuition.noTuitionRecords)
            } else {
                ForEach(viewModel.output.tuitionRecords) { record in
                    TuitionRecordCard(record: record)
                }
            }

        case .scholarship:
            if viewModel.output.scholarshipRecords.isEmpty {
                emptyState(L10n.Tuition.noScholarshipRecords)
            } else {
                ForEach(viewModel.output.scholarshipRecords) { record in
                    ScholarshipRecordCard(record: record)
                }
            }
        }
    }
    // API 응답이 빈 배열일때 표시할 문구
    private func emptyState(_ message: String) -> some View {
        Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.gray600)
                .frame(maxWidth: .infinity)
                .frame(maxWidth: 362)
                .frame(minHeight: 240)
    }
}

// 장학금 카드
private struct TuitionRecordCard: View {
    let record: TuitionRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 3.5) {
            HStack(alignment: .top, spacing: 8) {
                Text("\(record.year) \(record.semester.localizedName)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.black000)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Spacer(minLength: 8)

                TuitionStatusBadge(
                    title: record.registrationType.isEmpty ? "학기등록" : record.registrationType,
                    style: .neutral
                )
            }
            .frame(height: 22, alignment: .top)

            Text(CurrencyFormatter.won(record.paymentAmount))
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.black000)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(tuitionDetail)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.gray600)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.leading, 16)
        .padding(.trailing, 18)
        .padding(.top, 14)
        .frame(maxWidth: .infinity, minHeight: 93, alignment: .topLeading)
        .frame(maxWidth: 362)
        .background(.gray100)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var tuitionDetail: String {
        [
            "\(L10n.Tuition.tuitionDate) \(record.registrationDate)",
            "\(L10n.Tuition.reduction) \(CurrencyFormatter.won(record.reduction))"
        ]
        .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        .joined(separator: " · ")
    }
}

private struct ScholarshipRecordCard: View {
    let record: ScholarshipRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .top, spacing: 8) {
                Text(record.scholarshipName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.black000)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Spacer(minLength: 8)

                TuitionStatusBadge(
                    title: record.processStatus,
                    style: record.processStatus.contains("완료") ? .success : .neutral
                )
            }
            .frame(height: 19, alignment: .top)

            Text(CurrencyFormatter.won(record.actualAmount))
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.black000)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(scholarshipDetail)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.gray600)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.leading, 16)
        .padding(.trailing, 18)
        .padding(.top, 14)
        .frame(maxWidth: .infinity, minHeight: 93, alignment: .topLeading)
        .frame(maxWidth: 362)
        .background(.gray100)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var scholarshipDetail: String {
        [
            "\(record.year) \(record.semester.localizedName)",
            record.processDate,
            detailReason
        ]
        .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        .joined(separator: " · ")
    }

    private var detailReason: String {
        if !record.dropReason.isEmpty {
            return record.dropReason
        }
        if !record.note.isEmpty {
            return record.note
        }
        return record.paymentMethod
    }
}

private struct TuitionStatusBadge: View {
    enum Style {
        case neutral
        case success
    }

    let title: String
    let style: Style

    var body: some View {
        Text(title)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(foregroundColor)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .frame(height: 19)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private var foregroundColor: Color {
        switch style {
        case .neutral:
            .gray600
        case .success:
            .logoIndigo
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .neutral:
            .gray050
        case .success:
            .pointColor050
        }
    }
}

#Preview("Tuition") {
    let container = DIContainer.preview
    NavigationStack {
        TuitionView(
            viewModel: TuitionViewModel(repository: container.tuitionRepository)
        )
    }
}
