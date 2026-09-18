import SwiftUI

struct LoginView: View {
    @Bindable var authenticationState: AuthenticationState

    let onRegister: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false

    @FocusState private var focusedField: Field?

    private enum Field {
        case email
        case password
    }

    init(
        authenticationState: AuthenticationState,
        onRegister: @escaping () -> Void = {}
    ) {
        self.authenticationState = authenticationState
        self.onRegister = onRegister
    }

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 28
            ) {
                header
                form
                signInButton
                registerPrompt
                Spacer(minLength: 8)
            }
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.top, 32)
            .padding(.bottom, 32)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(
            FocuraColors.surface
                .ignoresSafeArea()
        )
        .safeAreaPadding(.bottom, 8)
        .task {
            focusedField = .email
        }
    }

    private var header: some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            Text("Welcome back")
                .font(
                    .system(
                        size: 14,
                        weight: .semibold
                    )
                )
                .foregroundStyle(FocuraColors.primary)

            Text("Log in to Focura")
                .font(
                    .system(
                        size: 28,
                        weight: .semibold
                    )
                )
                .foregroundStyle(FocuraColors.textPrimary)
                .tracking(-0.6)
                .fixedSize(horizontal: false, vertical: true)

            Text(
                "Continue protecting your attention and measuring your focus."
            )
            .font(FocuraTypography.body)
            .foregroundStyle(FocuraColors.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var form: some View {
        VStack(
            alignment: .leading,
            spacing: 18
        ) {
            fieldLabel("Email")
            emailField

            fieldLabel("Password")
            passwordField

            if let errorMessage = authenticationState.errorMessage {
                Label {
                    Text(errorMessage)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(
                        systemName: "exclamationmark.circle.fill"
                    )
                }
                .font(FocuraTypography.caption)
                .foregroundStyle(FocuraColors.danger)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("login.error")
            }
        }
    }

    private func fieldLabel(_ title: String) -> some View {
        Text(title)
            .font(FocuraTypography.bodyMedium)
            .foregroundStyle(FocuraColors.textPrimary)
    }

    private var emailField: some View {
        TextField(
            "you@example.com",
            text: $email
        )
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .keyboardType(.emailAddress)
        .textContentType(.username)
        .focused(
            $focusedField,
            equals: .email
        )
        .submitLabel(.next)
        .onSubmit {
            focusedField = .password
        }
        .font(FocuraTypography.body)
        .foregroundStyle(FocuraColors.textPrimary)
        .padding(.horizontal, 16)
        .frame(minHeight: 52)
        .background(
            Color(uiColor: .secondarySystemBackground)
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: FocuraRadius.large,
                style: .continuous
            )
            .stroke(
                focusedField == .email
                    ? FocuraColors.primary
                    : FocuraColors.border,
                lineWidth: focusedField == .email ? 1.5 : 1
            )
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: FocuraRadius.large,
                style: .continuous
            )
        )
        .accessibilityIdentifier("login.email")
        .accessibilityLabel("Email address")
    }

    private var passwordField: some View {
        HStack(spacing: 10) {
            Group {
                if isPasswordVisible {
                    TextField(
                        "Password",
                        text: $password
                    )
                } else {
                    SecureField(
                        "Password",
                        text: $password
                    )
                }
            }
            .textContentType(.password)
            .focused(
                $focusedField,
                equals: .password
            )
            .submitLabel(.go)
            .onSubmit {
                submit()
            }
            .font(FocuraTypography.body)
            .foregroundStyle(FocuraColors.textPrimary)

            Button {
                isPasswordVisible.toggle()
            } label: {
                Image(
                    systemName: isPasswordVisible
                        ? "eye.slash"
                        : "eye"
                )
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(FocuraColors.textSecondary)
                .frame(
                    width: 32,
                    height: 32
                )
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                isPasswordVisible
                    ? "Hide password"
                    : "Show password"
            )
            .accessibilityIdentifier(
                "login.passwordVisibility"
            )
        }
        .padding(.horizontal, 12)
        .frame(minHeight: 52)
        .background(
            Color(uiColor: .secondarySystemBackground)
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: FocuraRadius.large,
                style: .continuous
            )
            .stroke(
                focusedField == .password
                    ? FocuraColors.primary
                    : FocuraColors.border,
                lineWidth: focusedField == .password ? 1.5 : 1
            )
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: FocuraRadius.large,
                style: .continuous
            )
        )
        .accessibilityIdentifier("login.password")
    }

    private var signInButton: some View {
        Button {
            submit()
        } label: {
            Group {
                if authenticationState.isSubmitting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Sign In")
                }
            }
            .font(FocuraTypography.bodyMedium)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
        }
        .buttonStyle(FocuraPrimaryButtonStyle())
        .disabled(
            authenticationState.isSubmitting
            || email.trimmingCharacters(
                in: .whitespacesAndNewlines
            ).isEmpty
            || password.isEmpty
        )
        .accessibilityIdentifier("login.submit")
    }

    private var registerPrompt: some View {
        HStack(
            alignment: .center,
            spacing: 4
        ) {
            Text("Don't have an account?")
                .foregroundStyle(FocuraColors.textSecondary)

            Button("Create one") {
                onRegister()
            }
            .font(FocuraTypography.captionMedium)
            .foregroundStyle(FocuraColors.primary)
            .buttonStyle(.plain)
            .accessibilityIdentifier("login.register")
        }
        .font(FocuraTypography.caption)
        .frame(
            maxWidth: .infinity,
            alignment: .center
        )
    }

    private func submit() {
        focusedField = nil

        Task {
            await authenticationState.login(
                email: email,
                password: password,
                deviceName: "Focura iOS"
            )
        }
    }
}

#Preview {
    LoginView(
        authenticationState: AuthenticationState(
            repository: PreviewAuthRepository()
        )
    )
}

private struct PreviewAuthRepository: AuthRepository {
    func register(
        name: String,
        email: String,
        password: String,
        passwordConfirmation: String,
        deviceName: String
    ) async throws -> AuthUser {
        previewUser
    }

    func login(
        email: String,
        password: String,
        deviceName: String
    ) async throws -> AuthUser {
        previewUser
    }

    func restoreSession() async throws -> AuthUser? {
        nil
    }

    func me() async throws -> AuthUser {
        previewUser
    }

    func logout() async throws {}

    func claimVisitorSessions(
        visitorID: String
    ) async throws -> Int {
        0
    }

    private var previewUser: AuthUser {
        AuthUser(
            id: 1,
            name: "Focura User",
            email: "preview@focura.app",
            emailVerifiedAt: nil,
            createdAt: nil
        )
    }
}
