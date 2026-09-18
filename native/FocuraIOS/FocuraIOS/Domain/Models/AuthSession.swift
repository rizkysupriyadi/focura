import Foundation

struct AuthSession: Codable, Sendable, Equatable {
    let token: String
    let expiresAt: Date?

    init(
        token: String,
        expiresAt: Date? = nil
    ) {
        self.token = token
        self.expiresAt = expiresAt
    }
}
