import Foundation

struct FocusSession: Codable, Sendable, Equatable, Identifiable {
    let id: Int
    let userID: Int?
    let visitorID: String?
    let mode: TimerMode
    let title: String?
    let plannedDurationSeconds: Int
    let actualDurationSeconds: Int
    let focusedDurationSeconds: Int
    let interruptedDurationSeconds: Int
    let interruptionCount: Int
    let focusIntegrity: Double?
    let status: FocusSessionStatus
    let startedAt: Date
    let endedAt: Date?
    let interruptions: [FocusSessionInterruption]
    let createdAt: Date?
    let updatedAt: Date?
}

struct FocusSessionInterruption: Codable, Sendable, Equatable, Identifiable {
    let id: Int
    let focusSessionID: Int
    let startedAt: Date
    let endedAt: Date?
    let durationSeconds: Int
    let createdAt: Date?
    let updatedAt: Date?
}
