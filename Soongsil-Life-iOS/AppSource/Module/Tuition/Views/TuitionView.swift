import SwiftUI

struct TuitionView: View {
    @State var viewModel: TuitionViewModel

    var body: some View {
        VStack(spacing: 0) {
            if (viewModel.output.isLoadingSelectedTab || !viewModel.output.hasLoaded)
                && !viewModel.output.hasLoadedSelectedTab {
                ProgressView()
                    .tint(.serviceBlue600)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.output.errorMessage,
                      !viewModel.output.hasLoadedSelectedTab {
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
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 0) {
                        segmentedControl

                        content
                            .id(viewModel.output.selectedTab)
                            .transition(.opacity)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 32)
                    .animation(
                        .easeInOut(duration: 0.18),
                        value: viewModel.output.selectedTab
                    )
                }
                .refreshable {
                    await viewModel.transform(input: .load(force: true))
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
            await viewModel.transform(input: .load())
        }
        .alert(L10n.Home.tuitionScholarship, isPresented: showsError) {
            Button(L10n.Common.confirm, role: .cancel) {
                Task {
                    await viewModel.transform(input: .errorDismissed)
                }
            }
            Button(L10n.Tuition.retry) {
                Task {
                    await viewModel.transform(input: .load(force: true))
                }
            }
        } message: {
            Text(viewModel.output.errorMessage ?? "")
        }
    }

    private var showsError: Binding<Bool> {
        Binding(
            get: {
                viewModel.output.errorMessage != nil
                    && viewModel.output.hasLoadedSelectedTab
            },
            set: { isPresented in
                guard !isPresented else { return }
                Task {
                    await viewModel.transform(input: .errorDismissed)
                }
            }
        )
    }

    private var segmentedControl: some View {
        HStack(spacing: 0) {
            ForEach(TuitionViewModel.Tab.allCases, id: \.self) { tab in
                let isSelected = viewModel.output.selectedTab == tab
                Button {
                    Task {
                        await viewModel.transform(input: .selectTab(tab))
                    }
                } label: {
                    VStack(spacing: 0) {
                        Text(tab.title)
                            .font(.pretendard(14, weight: .semibold))
                            .foregroundStyle(
                                isSelected ? .serviceBlue600 : .serviceGray500
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        ZStack(alignment: .bottom) {
                            Rectangle()
                                .fill(.serviceGray200)
                                .frame(height: 1)

                            if isSelected {
                                Rectangle()
                                    .fill(.serviceBlue600)
                                    .frame(height: 2)
                            }
                        }
                        .frame(height: 2)
                    }
                    .frame(height: 43)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(.bottom, 7)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.output.selectedTab {
        case .tuition:
            if viewModel.output.isLoadingSelectedTab
                && !viewModel.output.hasLoadedSelectedTab {
                loadingState
            } else if viewModel.output.tuitionRecords.isEmpty {
                emptyState(L10n.Tuition.noTuitionRecords)
            } else {
                ForEach(viewModel.output.tuitionRecords) { record in
                    TuitionRecordRow(record: record)
                }
            }

        case .scholarship:
            if viewModel.output.isLoadingSelectedTab
                && !viewModel.output.hasLoadedSelectedTab {
                loadingState
            } else if viewModel.output.scholarshipRecords.isEmpty {
                emptyState(L10n.Tuition.noScholarshipRecords)
            } else {
                ForEach(viewModel.output.scholarshipRecords) { record in
                    ScholarshipRecordRow(record: record)
                }
            }
        }
    }

    private var loadingState: some View {
        ProgressView()
            .tint(.serviceBlue600)
            .frame(maxWidth: .infinity, minHeight: 240)
    }

    private func emptyState(_ message: String) -> some View {
        Text(message)
            .font(.pretendard(14, weight: .medium))
            .foregroundStyle(.serviceGray500)
            .frame(maxWidth: .infinity, minHeight: 240)
    }
}

private struct TuitionRecordRow: View {
    let record: TuitionRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                Text("\(record.year) \(record.semester.localizedName)")
                    .font(.pretendard(14, weight: .semibold))
                    .foregroundStyle(.black000)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Spacer(minLength: 8)

                TuitionStatusBadge(
                    title: record.registrationType.isEmpty
                        ? "학기등록"
                        : record.registrationType,
                    style: .neutral
                )
            }

            Text(CurrencyFormatter.won(record.paymentAmount))
                .font(.pretendard(21, weight: .semibold))
                .foregroundStyle(.black000)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(tuitionDetail)
                .font(.pretendard(13))
                .foregroundStyle(.serviceGray500)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: 105, alignment: .topLeading)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.serviceGray200)
                .frame(height: 1)
        }
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

private struct ScholarshipRecordRow: View {
    let record: ScholarshipRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top, spacing: 8) {
                Text(record.scholarshipName)
                    .font(.pretendard(14, weight: .semibold))
                    .foregroundStyle(.black000)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Spacer(minLength: 8)

                TuitionStatusBadge(
                    title: record.processStatus,
                    style: record.processStatus.contains("완료")
                        ? .success
                        : .neutral
                )
            }

            Text(CurrencyFormatter.won(record.actualAmount))
                .font(.pretendard(21, weight: .semibold))
                .foregroundStyle(.black000)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Text(scholarshipDetail)
                .font(.pretendard(13))
                .foregroundStyle(.serviceGray500)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: 105, alignment: .topLeading)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(.serviceGray200)
                .frame(height: 1)
        }
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
            .font(.pretendard(12, weight: .medium))
            .foregroundStyle(foregroundColor)
            .lineLimit(1)
            .padding(.horizontal, 7)
            .frame(height: 22)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
    }

    private var foregroundColor: Color {
        switch style {
        case .neutral:
            .serviceGray500
        case .success:
            .serviceBlue600
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .neutral:
            .gray100
        case .success:
            .serviceBlue500.opacity(0.1)
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
