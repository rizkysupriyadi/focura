import Foundation

struct CreateFocusSessionRequest: Encodable, Sendable, Equatable {
    let mode: TimerMode
    let title: String?
    let plannedDurationSeconds: Int
    let startedAt: Date
}

struct PauseFocusSessionRequest: Encodable, Sendable, Equatable {
    let startedAt: Date
}

struct ResumeFocusSessionRequest: Encodable, Sendable, Equatable {
    let endedAt: Date
}

struct CompleteFocusSessionRequest: Encodable, Sendable, Equatable {
    let endedAt: Date
}

struct CancelFocusSessionRequest: Encodable, Sendable, Equatable {
    let cancelledAt: Date
}

struct RecordSessionInterruptionRequest: Encodable, Sendable, Equatable {
    let startedAt: Date
    let endedAt: Date
}
