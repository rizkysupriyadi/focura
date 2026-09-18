import Foundation
import Observation

@MainActor
@Observable
final class AuthenticationState {
    enum Status: Equatable {
        case restoring
        case authenticated(AuthUser)
        case unauthenticated
    }

    private(set) var status: Status = .restoring
    private(set) var isSubmitting = false
    private(set) var errorMessage: String?

    private let repository: any AuthRepository

    init(repository: any AuthRepository) {
        self.repository = repository
    }

    func restoreSession() async {
        guard !isSubmitting else {
            return
        }

        status = .restoring
        errorMessage = nil

        do {
            guard let user = try await repository.restoreSession() else {
                status = .unauthenticated
                return
            }

            status = .authenticated(user)
        } catch {
            status = .unauthenticated
        }
    }

    func register(
        name: String,
        email: String,
        password: String,
        passwordConfirmation: String,
        deviceName: String
    ) async -> Bool {
        guard !isSubmitting else {
            return false
        }

        errorMessage = nil

        let normalizedName = name
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let normalizedEmail = email
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedName.isEmpty else {
            errorMessage = "Enter your name."
            return false
        }

        guard !normalizedEmail.isEmpty else {
            errorMessage = "Enter your email address."
            return false
        }

        guard !password.isEmpty else {
            errorMessage = "Create a password."
            return false
        }

        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters."
            return false
        }

        guard password == passwordConfirmation else {
            errorMessage = "Passwords do not match."
            return false
        }

        isSubmitting = true
        defer {
            isSubmitting = false
        }

        do {
            let user = try await repository.register(
                name: normalizedName,
                email: normalizedEmail,
                password: password,
                passwordConfirmation: passwordConfirmation,
                deviceName: deviceName
            )

            status = .authenticated(user)
            return true
        } catch {
            errorMessage = Self.registrationMessage(for: error)
            return false
        }
    }

    func login(
        email: String,
        password: String,
        deviceName: String
    ) async -> Bool {
        guard !isSubmitting else {
            return false
        }

        errorMessage = nil

        let normalizedEmail = email
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalizedEmail.isEmpty else {
            errorMessage = "Enter your email address."
            return false
        }

        guard !password.isEmpty else {
            errorMessage = "Enter your password."
            return false
        }

        isSubmitting = true
        defer {
            isSubmitting = false
        }

        do {
            let user = try await repository.login(
                email: normalizedEmail,
                password: password,
                deviceName: deviceName
            )

            status = .authenticated(user)
            return true
        } catch {
            errorMessage = Self.message(for: error)
            return false
        }
    }

    func logout() async {
        do {
            try await repository.logout()
        } catch {
            // The repository remains responsible for clearing
            // the local session when authentication has expired.
        }

        errorMessage = nil
        status = .unauthenticated
    }

    func setAuthenticatedUser(_ user: AuthUser) {
        errorMessage = nil
        status = .authenticated(user)
    }

    func clearError() {
        errorMessage = nil
    }

    private static func registrationMessage(for error: Error) -> String {
        guard let apiError = error as? APIError else {
            return "Something went wrong. Please try again."
        }

        switch apiError {
        case .validation(let message):
            return message ?? "Please check the information you entered."
        case .conflict:
            return "An account with this email already exists."
        case .network:
            return "Unable to connect. Check your internet connection and try again."
        case .server:
            return "Focura is temporarily unavailable. Please try again."
        case .unauthorized:
            return "Registration could not be completed."
        case .forbidden:
            return "Registration is currently unavailable."
        case .notFound:
            return "The registration service could not be reached."
        case .invalidURL,
             .invalidResponse,
             .decoding,
             .unknown:
            return "Something went wrong. Please try again."
        }
    }

    private static func message(for error: Error) -> String {
        guard let apiError = error as? APIError else {
            return "Something went wrong. Please try again."
        }

        switch apiError {
        case .validation:
            return "The email or password is incorrect."

        case .unauthorized:
            return "The email or password is incorrect."

        case .forbidden:
            return "You do not have permission to sign in."

        case .conflict:
            return "Your account is currently unavailable. Please try again."

        case .network:
            return "Unable to connect. Check your internet connection and try again."

        case .server:
            return "Focura is temporarily unavailable. Please try again."

        case .notFound:
            return "The sign-in service could not be reached."

        case .invalidURL,
             .invalidResponse,
             .decoding,
             .unknown:
            return "Something went wrong. Please try again."
        }
    }
}
