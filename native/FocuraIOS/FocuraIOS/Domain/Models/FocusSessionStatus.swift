import Foundation

enum FocusSessionStatus: String, Codable, Sendable, Equatable {
    case active
    case paused
    case completed
    case cancelled
}
