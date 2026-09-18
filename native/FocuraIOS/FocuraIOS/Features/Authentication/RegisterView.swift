import SwiftUI
import UIKit

struct RegisterView: View {
    @Bindable var authenticationState: AuthenticationState

    let onLogin: () -> Void

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var passwordConfirmation = ""
    @State private var isPasswordVisible = false
    @State private var isPasswordConfirmationVisible = false

    @FocusState private var focusedField: Field?

    private enum Field {
        case name
        case email
        case password
        case passwordConfirmation
    }

    init(
        authenticationState: AuthenticationState,
        onLogin: @escaping () -> Void = {}
    ) {
        self.authenticationState = authenticationState
        self.onLogin = onLogin
    }

    var body: some View {
        ScrollView {
            VStack(
                alignment: .leading,
                spacing: 28
            ) {
                header
                form
                createAccountButton
                loginPrompt
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
            focusedField = .name
        }
    }

    private var header: some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            Text("Get started")
                .font(
                    .system(
                        size: 14,
                        weight: .semibold
                    )
                )
                .foregroundStyle(FocuraColors.primary)

            Text("Create your Focura account")
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
                "Create an account to keep your focus history and insights with you."
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
            textField(
                title: "Name",
                placeholder: "Your name",
                text: $name,
                field: .name,
                contentType: .name
            )
            .textInputAutocapitalization(.words)

            textField(
                title: "Email",
                placeholder: "you@example.com",
                text: $email,
                field: .email,
                contentType: .emailAddress
            )
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()

            passwordField(
                title: "Password",
                placeholder: "At least 8 characters",
                text: $password,
                field: .password,
                contentType: .newPassword,
                isVisible: $isPasswordVisible
            )

            passwordField(
                title: "Confirm password",
                placeholder: "Re-enter your password",
                text: $passwordConfirmation,
                field: .passwordConfirmation,
                contentType: .newPassword,
                isVisible: $isPasswordConfirmationVisible
            )

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
                .accessibilityIdentifier("register.error")
            }
        }
    }

    private func textField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        field: Field,
        contentType: UITextContentType
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            Text(title)
                .font(FocuraTypography.bodyMedium)
                .foregroundStyle(FocuraColors.textPrimary)

            TextField(
                placeholder,
                text: text
            )
            .textContentType(contentType)
            .focused(
                $focusedField,
                equals: field
            )
            .submitLabel(.next)
            .onSubmit {
                advance(from: field)
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
                    focusedField == field
                        ? FocuraColors.primary
                        : FocuraColors.border,
                    lineWidth: focusedField == field ? 1.5 : 1
                )
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: FocuraRadius.large,
                    style: .continuous
                )
            )
            .accessibilityIdentifier(
                field == .name
                    ? "register.name"
                    : "register.email"
            )
            .accessibilityLabel(title)
        }
    }

    private func passwordField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        field: Field,
        contentType: UITextContentType,
        isVisible: Binding<Bool>
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            Text(title)
                .font(FocuraTypography.bodyMedium)
                .foregroundStyle(FocuraColors.textPrimary)

            HStack(spacing: 10) {
                Group {
                    if isVisible.wrappedValue {
                        TextField(
                            placeholder,
                            text: text
                        )
                    } else {
                        SecureField(
                            placeholder,
                            text: text
                        )
                    }
                }
                .textContentType(contentType)
                .focused(
                    $focusedField,
                    equals: field
                )
                .submitLabel(
                    field == .password
                        ? .next
                        : .done
                )
                .onSubmit {
                    if field == .passwordConfirmation {
                        submit()
                    } else {
                        advance(from: field)
                    }
                }
                .font(FocuraTypography.body)
                .foregroundStyle(FocuraColors.textPrimary)

                Button {
                    isVisible.wrappedValue.toggle()
                } label: {
                    Image(
                        systemName: isVisible.wrappedValue
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
                    isVisible.wrappedValue
                        ? "Hide \(title.lowercased())"
                        : "Show \(title.lowercased())"
                )
                .accessibilityIdentifier(
                    field == .password
                        ? "register.passwordVisibility"
                        : "register.passwordConfirmationVisibility"
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
                    focusedField == field
                        ? FocuraColors.primary
                        : FocuraColors.border,
                    lineWidth: focusedField == field ? 1.5 : 1
                )
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: FocuraRadius.large,
                    style: .continuous
                )
            )
            .accessibilityIdentifier(
                field == .password
                    ? "register.password"
                    : "register.passwordConfirmation"
            )
        }
    }

    private var createAccountButton: some View {
        Button {
            submit()
        } label: {
            Group {
                if authenticationState.isSubmitting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Create account")
                }
            }
            .font(FocuraTypography.bodyMedium)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 52)
        }
        .buttonStyle(FocuraPrimaryButtonStyle())
        .disabled(
            authenticationState.isSubmitting
                || name.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ).isEmpty
                || email.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ).isEmpty
                || password.isEmpty
                || passwordConfirmation.isEmpty
        )
        .accessibilityIdentifier("register.submit")
    }

    private var loginPrompt: some View {
        HStack(
            alignment: .center,
            spacing: 4
        ) {
            Text("Already have an account?")
                .foregroundStyle(FocuraColors.textSecondary)

            Button("Log in") {
                onLogin()
            }
            .font(FocuraTypography.captionMedium)
            .foregroundStyle(FocuraColors.primary)
            .buttonStyle(.plain)
            .accessibilityIdentifier("register.login")
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
            await authenticationState.register(
                name: name,
                email: email,
                password: password,
                passwordConfirmation: passwordConfirmation,
                deviceName: "Focura iOS"
            )
        }
    }

    private func advance(from field: Field) {
        switch field {
        case .name:
            focusedField = .email

        case .email:
            focusedField = .password

        case .password:
            focusedField = .passwordConfirmation

        case .passwordConfirmation:
            focusedField = nil
        }
    }
}

#Preview {
    RegisterView(
        authenticationState: AuthenticationState(
            repository: PreviewRegisterAuthRepository()
        )
    )
}

private struct PreviewRegisterAuthRepository: AuthRepository {
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
