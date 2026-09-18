import Foundation

struct TimerState: Codable, Sendable, Equatable {
    let mode: TimerMode
    let status: TimerStatus
    let durationSeconds: Int
    let startedAt: Date?
    let activeStartedAt: Date?
    let expectedEndAt: Date?
    let pausedAt: Date?
    let accumulatedElapsedSeconds: Int

    init(
        mode: TimerMode,
        status: TimerStatus = .idle,
        durationSeconds: Int,
        startedAt: Date? = nil,
        activeStartedAt: Date? = nil,
        expectedEndAt: Date? = nil,
        pausedAt: Date? = nil,
        accumulatedElapsedSeconds: Int = 0
    ) {
        precondition(
            durationSeconds > 0,
            "Timer duration must be greater than zero."
        )

        precondition(
            accumulatedElapsedSeconds >= 0,
            "Accumulated elapsed time cannot be negative."
        )

        self.mode = mode
        self.status = status
        self.durationSeconds = durationSeconds
        self.startedAt = startedAt
        self.activeStartedAt = activeStartedAt
        self.expectedEndAt = expectedEndAt
        self.pausedAt = pausedAt
        self.accumulatedElapsedSeconds = accumulatedElapsedSeconds
    }
}
