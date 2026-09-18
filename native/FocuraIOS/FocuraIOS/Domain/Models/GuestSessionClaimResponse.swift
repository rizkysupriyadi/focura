import Foundation

struct GuestSessionClaimResponse: Codable, Sendable, Equatable {
    let data: Payload
    let message: String

    struct Payload: Codable, Sendable, Equatable {
        let claimedCount: Int
    }
}
