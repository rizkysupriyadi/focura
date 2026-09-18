import Foundation

struct RemoteFocusSessionRepository: FocusSessionRepository, Sendable {
    private let apiClient: APIClient
    private let authSessionStore: AuthSessionStore
    private let visitorIdentityStore: VisitorIdentityStore

    init(
        apiClient: APIClient,
        authSessionStore: AuthSessionStore,
        visitorIdentityStore: VisitorIdentityStore
    ) {
        self.apiClient = apiClient
        self.authSessionStore = authSessionStore
        self.visitorIdentityStore = visitorIdentityStore
    }

    func create(
        mode: TimerMode,
        title: String?,
        plannedDurationSeconds: Int,
        startedAt: Date
    ) async throws -> FocusSession {
        let payload = CreateFocusSessionRequest(
            mode: mode,
            title: title,
            plannedDurationSeconds: plannedDurationSeconds,
            startedAt: startedAt
        )

        let response = try await request(
            path: "/focus-sessions",
            method: "POST",
            body: try encode(payload)
        )

        return try decodeResource(
            FocusSession.self,
            from: response.data
        )
    }

    func pause(
        sessionID: Int,
        startedAt: Date
    ) async throws -> FocusSession {
        let payload = PauseFocusSessionRequest(
            startedAt: startedAt
        )

        let response = try await request(
            path: "/focus-sessions/\(sessionID)/pause",
            method: "POST",
            body: try encode(payload)
        )

        return try decodeResource(
            FocusSession.self,
            from: response.data
        )
    }

    func resume(
        sessionID: Int,
        endedAt: Date
    ) async throws -> FocusSession {
        let payload = ResumeFocusSessionRequest(
            endedAt: endedAt
        )

        let response = try await request(
            path: "/focus-sessions/\(sessionID)/resume",
            method: "POST",
            body: try encode(payload)
        )

        return try decodeResource(
            FocusSession.self,
            from: response.data
        )
    }

    func complete(
        sessionID: Int,
        endedAt: Date
    ) async throws -> FocusSession {
        let payload = CompleteFocusSessionRequest(
            endedAt: endedAt
        )

        let response = try await request(
            path: "/focus-sessions/\(sessionID)/complete",
            method: "POST",
            body: try encode(payload)
        )

        return try decodeResource(
            FocusSession.self,
            from: response.data
        )
    }

    func cancel(
        sessionID: Int,
        cancelledAt: Date
    ) async throws -> FocusSession {
        let payload = CancelFocusSessionRequest(
            cancelledAt: cancelledAt
        )

        let response = try await request(
            path: "/focus-sessions/\(sessionID)/cancel",
            method: "POST",
            body: try encode(payload)
        )

        return try decodeResource(
            FocusSession.self,
            from: response.data
        )
    }

    func recordInterruption(
        sessionID: Int,
        startedAt: Date,
        endedAt: Date
    ) async throws -> FocusSessionInterruption {
        let payload = RecordSessionInterruptionRequest(
            startedAt: startedAt,
            endedAt: endedAt
        )

        let response = try await request(
            path: "/focus-sessions/\(sessionID)/interruptions",
            method: "POST",
            body: try encode(payload)
        )

        return try decodeResource(
            FocusSessionInterruption.self,
            from: response.data
        )
    }

    private func request(
        path: String,
        method: String,
        body: Data?
    ) async throws -> HTTPResponse {
        var headers: [String: String] = [
            "Content-Type": "application/json",
        ]

        if let session = try await authSessionStore.load() {
            if let expiresAt = session.expiresAt,
               expiresAt <= Date() {
                try await authSessionStore.clear()
                throw APIError.unauthorized
            }

            headers["Authorization"] = "Bearer \(session.token)"
        } else {
            headers["X-Visitor-Id"] =
                try await visitorIdentityStore.visitorID()
        }

        return try await apiClient.request(
            path: path,
            method: method,
            headers: headers,
            body: body
        )
    }

    private func encode<T: Encodable>(
        _ value: T
    ) throws -> Data {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601

        do {
            return try encoder.encode(value)
        } catch {
            throw APIError.unknown(
                message: "Failed to encode request: \(error.localizedDescription)"
            )
        }
    }

    private func decodeResource<T: Decodable>(
        _ type: T.Type,
        from data: Data
    ) throws -> T {
        do {
            return try APIJSONDecoder.make().decode(
                ResourceEnvelope<T>.self,
                from: data
            ).data
        } catch {
            throw APIError.decoding(
                message: error.localizedDescription
            )
        }
    }
}

private struct ResourceEnvelope<T: Decodable>: Decodable {
    let data: T
}
