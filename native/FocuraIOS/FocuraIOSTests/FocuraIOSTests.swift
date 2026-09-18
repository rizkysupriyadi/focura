import XCTest

import Foundation
import Testing
@testable import FocuraIOS

@Test
func focuraIOSLoads() {
    #expect(true)
}

@Test
func appConfigurationUsesExpectedAPIPath() {
    let configuration = AppConfiguration(
        environment: .production,
        apiBaseURL: URL(string: "https://example.com/api/v1")!
    )

    #expect(
        configuration.apiBaseURL.absoluteString
        == "https://example.com/api/v1"
    )
}

@Test
func authSessionPreservesTokenAndExpiration() {
    let expiration = Date(timeIntervalSince1970: 1_800_000_000)

    let session = AuthSession(
        token: "test-token",
        expiresAt: expiration
    )

    #expect(session.token == "test-token")
    #expect(session.expiresAt == expiration)
}

@Test
func apiErrorIdentifiesUnauthorizedResponses() {
    #expect(APIError.unauthorized.isAuthenticationFailure)
    #expect(!APIError.conflict.isAuthenticationFailure)
}

@Test
func authSessionStorePersistsAndClearsSession() async throws {
    let secureStore = InMemorySecureStore()
    let store = AuthSessionStore(
        secureStore: secureStore
    )

    let expiration = Date(
        timeIntervalSince1970: 1_800_000_000
    )

    let session = AuthSession(
        token: "session-token",
        expiresAt: expiration
    )

    try await store.save(session)

    let loaded = try await store.load()

    #expect(loaded == session)

    try await store.clear()

    #expect(try await store.load() == nil)
}

private final class InMemorySecureStore: SecureStore, @unchecked Sendable {
    private var values: [String: String] = [:]

    func set(
        _ value: String,
        forKey key: String
    ) throws {
        values[key] = value
    }

    func string(
        forKey key: String
    ) throws -> String? {
        values[key]
    }

    func delete(
        forKey key: String
    ) throws {
        values.removeValue(forKey: key)
    }
}

@MainActor
final class RegistrationStateTests: XCTestCase {
    func testRegisterRejectsEmptyName() async {
        let repository = RegistrationTestRepository()
        let state = AuthenticationState(repository: repository)

        let result = await state.register(
            name: "",
            email: "user@example.com",
            password: "password123",
            passwordConfirmation: "password123",
            deviceName: "Focura iOS"
        )

        XCTAssertFalse(result)
        XCTAssertEqual(
            state.errorMessage,
            "Enter your name."
        )
        XCTAssertEqual(
            state.status,
            .restoring
        )
        XCTAssertFalse(repository.registerCalled)
    }

    func testRegisterRejectsShortPassword() async {
        let repository = RegistrationTestRepository()
        let state = AuthenticationState(repository: repository)

        let result = await state.register(
            name: "Rizky",
            email: "user@example.com",
            password: "short",
            passwordConfirmation: "short",
            deviceName: "Focura iOS"
        )

        XCTAssertFalse(result)
        XCTAssertEqual(
            state.errorMessage,
            "Password must be at least 8 characters."
        )
        XCTAssertFalse(repository.registerCalled)
    }

    func testRegisterRejectsMismatchedPasswords() async {
        let repository = RegistrationTestRepository()
        let state = AuthenticationState(repository: repository)

        let result = await state.register(
            name: "Rizky",
            email: "user@example.com",
            password: "password123",
            passwordConfirmation: "password456",
            deviceName: "Focura iOS"
        )

        XCTAssertFalse(result)
        XCTAssertEqual(
            state.errorMessage,
            "Passwords do not match."
        )
        XCTAssertFalse(repository.registerCalled)
    }

    func testRegisterAuthenticatesReturnedUser() async {
        let repository = RegistrationTestRepository()
        let state = AuthenticationState(repository: repository)

        let result = await state.register(
            name: "  Rizky  ",
            email: "  rizky@example.com  ",
            password: "password123",
            passwordConfirmation: "password123",
            deviceName: "Focura iOS"
        )

        XCTAssertTrue(result)
        XCTAssertNil(state.errorMessage)
        XCTAssertEqual(
            state.status,
            .authenticated(repository.user)
        )
        XCTAssertTrue(repository.registerCalled)
        XCTAssertEqual(repository.receivedName, "Rizky")
        XCTAssertEqual(repository.receivedEmail, "rizky@example.com")
    }

    func testRegisterMapsConflictError() async {
        let repository = RegistrationTestRepository(
            error: APIError.conflict
        )
        let state = AuthenticationState(repository: repository)

        let result = await state.register(
            name: "Rizky",
            email: "existing@example.com",
            password: "password123",
            passwordConfirmation: "password123",
            deviceName: "Focura iOS"
        )

        XCTAssertFalse(result)
        XCTAssertEqual(
            state.errorMessage,
            "An account with this email already exists."
        )
        XCTAssertEqual(
            state.status,
            .restoring
        )
    }
}

private final class RegistrationTestRepository: AuthRepository, @unchecked Sendable {
    let user = AuthUser(
        id: 42,
        name: "Rizky",
        email: "rizky@example.com",
        emailVerifiedAt: nil,
        createdAt: nil
    )

    let error: Error?

    private(set) var registerCalled = false
    private(set) var receivedName: String?
    private(set) var receivedEmail: String?

    init(error: Error? = nil) {
        self.error = error
    }

    func register(
        name: String,
        email: String,
        password: String,
        passwordConfirmation: String,
        deviceName: String
    ) async throws -> AuthUser {
        registerCalled = true
        receivedName = name
        receivedEmail = email

        if let error {
            throw error
        }

        return user
    }

    func login(
        email: String,
        password: String,
        deviceName: String
    ) async throws -> AuthUser {
        user
    }

    func restoreSession() async throws -> AuthUser? {
        nil
    }

    func me() async throws -> AuthUser {
        user
    }

    func logout() async throws {}

    func claimVisitorSessions(
        visitorID: String
    ) async throws -> Int {
        0
    }
}
