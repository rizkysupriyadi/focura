import Foundation

struct RemoteAuthRepository: AuthRepository, Sendable {
    private let apiClient: APIClient
    private let sessionStore: AuthSessionStore

    init(
        apiClient: APIClient,
        sessionStore: AuthSessionStore
    ) {
        self.apiClient = apiClient
        self.sessionStore = sessionStore
    }

    func register(
        name: String,
        email: String,
        password: String,
        passwordConfirmation: String,
        deviceName: String
    ) async throws -> AuthUser {
        let payload = MobileRegisterRequest(
            name: name,
            email: email,
            password: password,
            passwordConfirmation: passwordConfirmation,
            deviceName: deviceName
        )

        let response = try await apiClient.request(
            path: "/mobile/auth/register",
            method: "POST",
            headers: jsonHeaders,
            body: try encode(payload)
        )

        let decoded = try decode(
            AuthAPIResponse.self,
            from: response.data
        )

        try await persistSession(from: decoded)

        return decoded.data.user
    }

    func login(
        email: String,
        password: String,
        deviceName: String
    ) async throws -> AuthUser {
        let payload = MobileLoginRequest(
            email: email,
            password: password,
            deviceName: deviceName
        )

        let response = try await apiClient.request(
            path: "/mobile/auth/login",
            method: "POST",
            headers: jsonHeaders,
            body: try encode(payload)
        )

        let decoded = try decode(
            AuthAPIResponse.self,
            from: response.data
        )

        try await persistSession(from: decoded)

        return decoded.data.user
    }

    func restoreSession() async throws -> AuthUser? {
        guard let session = try await sessionStore.load() else {
            return nil
        }

        if let expiresAt = session.expiresAt,
           expiresAt <= Date() {
            try await sessionStore.clear()
            return nil
        }

        do {
            return try await me()
        } catch APIError.unauthorized {
            try await sessionStore.clear()
            return nil
        }
    }

    func me() async throws -> AuthUser {
        let response = try await apiClient.request(
            path: "/mobile/auth/me",
            headers: try await authenticatedHeaders()
        )

        let decoded = try decode(
            AuthMeResponse.self,
            from: response.data
        )

        return decoded.data
    }

    func logout() async throws {
        guard try await sessionStore.load() != nil else {
            return
        }

        do {
            _ = try await apiClient.request(
                path: "/mobile/auth/logout",
                method: "POST",
                headers: try await authenticatedHeaders()
            )
        } catch APIError.unauthorized {
            try await sessionStore.clear()
            return
        }

        try await sessionStore.clear()
    }

    func claimVisitorSessions(
        visitorID: String
    ) async throws -> Int {
        let response = try await apiClient.request(
            path: "/mobile/focus-sessions/claim",
            method: "POST",
            headers: try await authenticatedHeaders(
                additional: [
                    "X-Visitor-Id": visitorID,
                ]
            )
        )

        let decoded = try decode(
            GuestSessionClaimResponse.self,
            from: response.data
        )

        return decoded.data.claimedCount
    }

    private var jsonHeaders: [String: String] {
        [
            "Content-Type": "application/json",
        ]
    }

    private func authenticatedHeaders(
        additional: [String: String] = [:]
    ) async throws -> [String: String] {
        guard let session = try await sessionStore.load() else {
            throw APIError.unauthorized
        }

        if let expiresAt = session.expiresAt,
           expiresAt <= Date() {
            try await sessionStore.clear()
            throw APIError.unauthorized
        }

        var headers = additional
        headers["Authorization"] = "Bearer \(session.token)"

        return headers
    }

    private func persistSession(
        from response: AuthAPIResponse
    ) async throws {
        try await sessionStore.save(
            AuthSession(
                token: response.data.token,
                expiresAt: response.data.expiresAt
            )
        )
    }

    private func encode<T: Encodable>(
        _ value: T
    ) throws -> Data {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        do {
            return try encoder.encode(value)
        } catch {
            throw APIError.unknown(
                message: "Failed to encode request: \(error.localizedDescription)"
            )
        }
    }

    private func decode<T: Decodable>(
        _ type: T.Type,
        from data: Data
    ) throws -> T {
        do {
            return try APIJSONDecoder.make().decode(
                type,
                from: data
            )
        } catch {
            throw APIError.decoding(
                message: error.localizedDescription
            )
        }
    }
}
