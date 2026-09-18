import Foundation

struct MobileLoginRequest: Codable, Sendable, Equatable {
    let email: String
    let password: String
    let deviceName: String
}

struct MobileRegisterRequest: Codable, Sendable, Equatable {
    let name: String
    let email: String
    let password: String
    let passwordConfirmation: String
    let deviceName: String
}
