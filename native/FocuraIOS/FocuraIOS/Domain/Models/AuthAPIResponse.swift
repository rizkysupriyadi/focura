import Foundation

struct AuthAPIResponse: Codable, Sendable, Equatable {
    let data: AuthPayload
    let message: String

    struct AuthPayload: Codable, Sendable, Equatable {
        let token: String
        let tokenType: String
        let expiresAt: Date?
        let user: AuthUser
    }
}

struct AuthMeResponse: Codable, Sendable, Equatable {
    let data: AuthUser
}

struct LogoutResponse: Codable, Sendable, Equatable {
    let data: EmptyResponseData?
    let message: String
}

struct EmptyResponseData: Codable, Sendable, Equatable {
}
