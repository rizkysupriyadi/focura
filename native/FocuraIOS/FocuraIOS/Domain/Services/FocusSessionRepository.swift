import Foundation

protocol FocusSessionRepository: Sendable {
    func list(
        page: Int,
        perPage: Int,
        mode: TimerMode?,
        status: FocusSessionStatus?
    ) async throws -> FocusSessionPage

    func create(
        mode: TimerMode,
        title: String?,
        plannedDurationSeconds: Int,
        startedAt: Date
    ) async throws -> FocusSession

    func pause(
        sessionID: Int,
        startedAt: Date
    ) async throws -> FocusSession

    func resume(
        sessionID: Int,
        endedAt: Date
    ) async throws -> FocusSession

    func complete(
        sessionID: Int,
        endedAt: Date
    ) async throws -> FocusSession

    func cancel(
        sessionID: Int,
        cancelledAt: Date
    ) async throws -> FocusSession

    func recordInterruption(
        sessionID: Int,
        startedAt: Date,
        endedAt: Date
    ) async throws -> FocusSessionInterruption
}
