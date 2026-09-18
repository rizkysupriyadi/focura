import Foundation

enum TimerStatus: String, Codable, Sendable, Equatable, CaseIterable {
    case idle
    case running
    case paused
    case completed
}
