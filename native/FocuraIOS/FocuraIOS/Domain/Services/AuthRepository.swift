import Foundation

protocol AuthRepository: Sendable {
    func register(
        name: String,
        email: String,
        password: String,
        passwordConfirmation: String,
        deviceName: String
    ) async throws -> AuthUser

    func login(
        email: String,
        password: String,
        deviceName: String
    ) async throws -> AuthUser

    func restoreSession() async throws -> AuthUser?

    func me() async throws -> AuthUser

    func logout() async throws

    func claimVisitorSessions(
        visitorID: String
    ) async throws -> Int
}
