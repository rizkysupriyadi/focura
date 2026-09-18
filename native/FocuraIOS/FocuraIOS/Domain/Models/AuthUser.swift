import Foundation

struct AuthUser: Codable, Sendable, Equatable, Identifiable {
    let id: Int
    let name: String
    let email: String
    let emailVerifiedAt: Date?
    let createdAt: Date?
}
