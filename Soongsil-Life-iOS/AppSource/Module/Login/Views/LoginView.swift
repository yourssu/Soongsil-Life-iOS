import SwiftUI

struct LoginView: View {
    private enum FocusedField: Hashable {
        case studentID
        case password
    }

    @State var viewModel: LoginViewModel
    @State private var isPasswordSecured = true
    @State private var showsPasswordHelp = false
    @FocusState private var focusedField: FocusedField?

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    appLogo
                        .padding(.top, 61)

                    Text(L10n.Soomsil.loginHeading)
                        .font(.pretendard(28, weight: .bold))
                        .foregroundStyle(.black000)
                        .lineSpacing(8)
                        .padding(.top, 38)

                    Text(L10n.Soomsil.loginDescription)
                        .font(.pretendard(15, weight: .medium))
                        .foregroundStyle(.serviceGray500)
                        .padding(.top, 8)

                    VStack(spacing: 12) {
                        inputField(
                            title: L10n.Login.studentID,
                            text: studentIDBinding,
                            secure: false,
                            field: .studentID
                        )

                        inputField(
                            title: L10n.Login.password,
                            text: passwordBinding,
                            secure: true,
                            field: .password
                        )
                    }
                    .padding(.top, 52)

                    Button {
                        focusedField = nil
                        showsPasswordHelp = true
                    } label: {
                        Text(L10n.Login.forgotPassword)
                            .font(.pretendard(14, weight: .medium))
                            .foregroundStyle(.serviceBlue500)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, 16)

                    if let errorMessage = viewModel.output.errorMessage {
                        Text(errorMessage)
                            .font(.pretendard(13, weight: .medium))
                            .foregroundStyle(.warningRed500)
                            .padding(.top, 16)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 96)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .scrollDismissesKeyboard(.interactively)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                loginButton
                    .padding(.horizontal, 14)
                    .padding(.top, focusedField == nil ? 0 : 12)
                    .padding(.bottom, focusedField == nil ? 18 : 12)
                    .background(.white000)
            }
            .onChange(of: focusedField) { _, field in
                guard let field else { return }
                withAnimation(.easeOut(duration: 0.22)) {
                    proxy.scrollTo(field, anchor: field == .password ? .center : .top)
                }
            }
        }
        .background {
            Rectangle()
                .fill(.white000)
                .ignoresSafeArea()
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert(
            L10n.Login.passwordHelpTitle,
            isPresented: $showsPasswordHelp
        ) {
            Button(L10n.Common.confirm, role: .cancel) {}
        } message: {
            Text(L10n.Login.passwordHelpMessage)
        }
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
        ZStack(alignment: .topLeading) {
            Image("soomsilLogo")
                .resizable()
                .frame(width: 99, height: 48)
                .offset(x: -3, y: -3)
        }
        .frame(width: 96, height: 42, alignment: .topLeading)
        .accessibilityHidden(true)
    }

    private var loginButton: some View {
        Button {
            focusedField = nil
            Task {
                await viewModel.transform(input: .loginButtonTapped)
            }
        } label: {
            Text(L10n.Login.action)
                .font(.pretendard(18, weight: .semibold))
                .foregroundStyle(.white000)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    viewModel.output.canLogin
                        ? .serviceBlue600
                        : .serviceGray300
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.output.canLogin)
    }

    private func inputField(
        title: String,
        text: Binding<String>,
        secure: Bool,
        field: FocusedField
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.pretendard(16, weight: .medium))
                .foregroundStyle(.serviceGray500)

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
            .font(.pretendard(16, weight: .medium))
            .foregroundStyle(.serviceGray300)

            if secure {
                Button {
                    isPasswordSecured.toggle()
                    focusedField = .password
                } label: {
                    Image(systemName: isPasswordSecured ? "eye" : "eye.slash")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.serviceGray300)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }
        }
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .padding(.horizontal, 20)
        .frame(height: 52)
        .background(.white000)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(.gray100, lineWidth: 1)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            focusedField = field
        }
        .id(field)
    }
}

struct LoginLoadingView: View {
    var body: some View {
        VStack(spacing: 39) {
            Image("loginLoadingIndicator")
                .resizable()
                .scaledToFit()
                .frame(width: 112, height: 112)
                .offset(x: 2)
                .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text(L10n.Login.loadingTitle)
                    .font(.pretendard(28, weight: .bold))
                    .foregroundStyle(.black000)

                Text(L10n.Login.loadingDescription)
                    .font(.pretendard(15, weight: .medium))
                    .foregroundStyle(.serviceGray500)
            }
        }
        .offset(y: -62)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.white000)
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
    LoginView(
        viewModel: LoginViewModel(
            repository: repository,
            appFlow: AppFlowViewModel(
                repository: repository,
                consentStore: InMemoryAgreementConsentStore()
            )
        )
    )
}

#Preview("Login loading") {
    LoginLoadingView()
}
