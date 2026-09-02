import SwiftUI

struct LoginView: View {
    private enum FocusedField: Hashable {
        case studentID
        case password
    }

    @State var viewModel: LoginViewModel
    @State private var isPasswordSecured = true
    @FocusState private var focusedField: FocusedField?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                appLogo
                    .padding(.top, 32)
                    .padding(.bottom, 44)

                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.Soomsil.loginHeading)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.black000)
                        .lineSpacing(4)

                    Text(L10n.Soomsil.loginDescription)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.gray600)
                }
                .padding(.bottom, 78)

                VStack(spacing: 12) {
                    inputRow(
                        title: L10n.Login.studentID,
                        text: studentIDBinding,
                        secure: false,
                        field: .studentID
                    )
                    inputRow(
                        title: L10n.Login.password,
                        text: passwordBinding,
                        secure: true,
                        field: .password
                    )
                }
                .padding(.bottom, 18)

                if let errorMessage = viewModel.output.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.red)
                        .padding(.horizontal, 4)
                        .padding(.bottom, 18)
                } else {
                    Spacer().frame(height: 36)
                }

                Button {
                    Task {
                        await viewModel.transform(input: .loginButtonTapped)
                    }
                } label: {
                    Group {
                        if viewModel.output.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(L10n.Login.action)
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(.pointColor600)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.output.canLogin)
                .opacity(viewModel.output.canLogin ? 1 : 0.45)

                VStack(spacing: 8) {
                    Text(L10n.Login.credentialNotice)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.gray600)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 18) {
                        legalLink(
                            title: L10n.Settings.terms,
                            kind: .terms
                        )
                        legalLink(
                            title: L10n.Settings.privacy,
                            kind: .privacy
                        )
                    }

                    Text(L10n.Login.unofficialNotice)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.gray600)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 14)
                .padding(.bottom, 28)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 28)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .scrollDismissesKeyboard(.interactively)
        .background {
            Rectangle()
                .fill(.white000)
                .ignoresSafeArea()
        }
        .overlay {
            if viewModel.output.isLoading {
                SoomsilLoadingOverlay()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var studentIDBinding: Binding<String> {
        Binding(
            get: { viewModel.output.studentID },
            set: viewModel.updateStudentID
        )
    }

    private var passwordBinding: Binding<String> {
        Binding(
            get: { viewModel.output.password },
            set: viewModel.updatePassword
        )
    }

    private var appLogo: some View {
        Image("soomsilAppIcon")
            .resizable()
            .scaledToFit()
            .frame(width: 96, height: 96)
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
            .accessibilityHidden(true)
    }

    private func legalLink(
        title: String,
        kind: LegalDocumentKind
    ) -> some View {
        NavigationLink {
            LegalDocumentView(document: kind.document)
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.pointColor600)
                .underline()
                .frame(minHeight: 32)
        }
        .buttonStyle(.plain)
    }

    private func inputRow(
        title: String,
        text: Binding<String>,
        secure: Bool,
        field: FocusedField
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.gray600)

            Group {
                if secure && isPasswordSecured {
                    SecureField("", text: text)
                        .textContentType(.password)
                } else {
                    TextField("", text: text)
                        .textContentType(secure ? .password : .username)
                        .keyboardType(secure ? .default : .numberPad)
                }
            }
            .focused($focusedField, equals: field)
            .multilineTextAlignment(.trailing)

            if secure {
                Button {
                    isPasswordSecured.toggle()
                    focusedField = .password
                } label: {
                    Image(systemName: isPasswordSecured ? "eye" : "eye.slash")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.gray600)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }
        }
        .font(.system(size: 16, weight: .bold))
        .foregroundStyle(.black000)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .padding(.horizontal, 24)
        .frame(height: 58)
        .background(.white000)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.gray100, lineWidth: 1)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            focusedField = field
        }
    }
}

#Preview("Login") {
    let repository = AuthenticationRepository(
        service: MockAuthenticationService(
            isLoggedIn: false,
            delay: .zero
        ),
        credentialsStore: InMemoryLoginCredentialsStore()
    )
    NavigationStack {
        LoginView(
            viewModel: LoginViewModel(
                repository: repository,
                appFlow: AppFlowViewModel(repository: repository)
            )
        )
    }
}
