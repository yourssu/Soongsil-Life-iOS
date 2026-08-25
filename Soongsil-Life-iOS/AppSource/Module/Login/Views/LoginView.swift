import SwiftUI

struct LoginView: View {
    @State var viewModel: LoginViewModel
    @State private var isPasswordSecured = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            appLogo
                .padding(.top, 32)
                .padding(.bottom, 44)

            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.Soomsil.loginHeading)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.soomsilPrimaryText)
                    .lineSpacing(4)

                Text(L10n.Soomsil.loginDescription)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.soomsilSecondaryText)
            }
            .padding(.bottom, 78)

            VStack(spacing: 12) {
                inputRow(
                    title: L10n.Login.studentID,
                    text: studentIDBinding,
                    secure: false
                )
                inputRow(
                    title: L10n.Login.password,
                    text: passwordBinding,
                    secure: true
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
                .background(Color.soomsilBlue600)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!viewModel.output.canLogin)
            .opacity(viewModel.output.canLogin ? 1 : 0.45)

            Spacer()
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.soomsilBackground)
        .contentShape(Rectangle())
        .onTapGesture { hideKeyboard() }
        .overlay {
            if viewModel.output.isLoading {
                SoomsilLoadingOverlay()
            }
        }
    }

    private var studentIDBinding: Binding<String> {
        Binding(
            get: { viewModel.output.studentID },
            set: { value in
                Task {
                    await viewModel.transform(input: .studentIDChanged(value))
                }
            }
        )
    }

    private var passwordBinding: Binding<String> {
        Binding(
            get: { viewModel.output.password },
            set: { value in
                Task {
                    await viewModel.transform(input: .passwordChanged(value))
                }
            }
        )
    }

    private var appLogo: some View {
        ZStack {
            LinearGradient(
                colors: [Color.soomsilBlue600, Color.soomsilBlue500],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: "building.columns.fill")
                .font(.system(size: 42, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: 96, height: 96)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private func inputRow(
        title: String,
        text: Binding<String>,
        secure: Bool
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.soomsilSecondaryText)

            if secure && isPasswordSecured {
                SecureField("", text: text)
                    .textContentType(.password)
                    .multilineTextAlignment(.trailing)
            } else {
                TextField("", text: text)
                    .textContentType(secure ? .password : .username)
                    .keyboardType(secure ? .default : .numberPad)
                    .multilineTextAlignment(.trailing)
            }

            if secure {
                Button {
                    isPasswordSecured.toggle()
                } label: {
                    Image(systemName: isPasswordSecured ? "eye" : "eye.slash")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.soomsilSecondaryText)
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
            }
        }
        .font(.system(size: 16, weight: .bold))
        .foregroundStyle(Color.soomsilPrimaryText)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .padding(.horizontal, 24)
        .frame(height: 58)
        .background(Color.soomsilInputSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.soomsilBorder, lineWidth: 1)
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

#Preview("Login") {
    let repository = AuthenticationRepository(
        service: MockAuthenticationService(
            isLoggedIn: false,
            delay: .zero
        )
    )
    LoginView(
        viewModel: LoginViewModel(
            repository: repository,
            appFlow: AppFlowViewModel(repository: repository)
        )
    )
}
