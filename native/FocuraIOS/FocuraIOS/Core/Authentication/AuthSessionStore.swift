import Foundation

actor AuthSessionStore {
    private let secureStore: any SecureStore
    private let tokenKey = "auth.token"
    private let expirationKey = "auth.expiration"

    init(
        secureStore: any SecureStore = KeychainStore()
    ) {
        self.secureStore = secureStore
    }

    func save(_ session: AuthSession) throws {
        try secureStore.set(
            session.token,
            forKey: tokenKey
        )

        if let expiresAt = session.expiresAt {
            let value = String(
                expiresAt.timeIntervalSince1970
            )

            try secureStore.set(
                value,
                forKey: expirationKey
            )
        } else {
            try? secureStore.delete(
                forKey: expirationKey
            )
        }
    }

    func load() throws -> AuthSession? {
        guard let token = try secureStore.string(
            forKey: tokenKey
        ) else {
            return nil
        }

        let expiresAt: Date?

        if let value = try secureStore.string(
            forKey: expirationKey
        ),
        let timestamp = TimeInterval(value) {
            expiresAt = Date(
                timeIntervalSince1970: timestamp
            )
        } else {
            expiresAt = nil
        }

        return AuthSession(
            token: token,
            expiresAt: expiresAt
        )
    }

    func clear() throws {
        try secureStore.delete(
            forKey: tokenKey
        )

        try secureStore.delete(
            forKey: expirationKey
        )
    }
}
