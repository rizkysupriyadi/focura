import Foundation
import Combine

@MainActor
final class FocusSessionStore: ObservableObject {
    @Published private(set) var session: FocusSession?
    @Published private(set) var isSynchronizing = false
    @Published private(set) var lastError: APIError?
    @Published private(set) var isCreating = false

    private let repository: any FocusSessionRepository
    private var creationTask: Task<Void, Never>?

    init(repository: any FocusSessionRepository) {
        self.repository = repository
    }

    var isActive: Bool {
        session?.status == .active
    }

    var isPaused: Bool {
        session?.status == .paused
    }

    var hasServerSession: Bool {
        guard let status = session?.status else {
            return false
        }

        return status == .active || status == .paused
    }

    var isCompleted: Bool {
        session?.status == .completed
    }

    func start(
        mode: TimerMode,
        title: String?,
        plannedDurationSeconds: Int,
        startedAt: Date
    ) async -> Bool {
        guard !isCreating else {
            return false
        }

        isCreating = true
        isSynchronizing = true
        lastError = nil

        let repository = self.repository

        creationTask = Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            do {
                let created = try await repository.create(
                    mode: mode,
                    title: title,
                    plannedDurationSeconds: plannedDurationSeconds,
                    startedAt: startedAt
                )

                self.session = created
            } catch let error as APIError {
                self.lastError = error
                print(
                    "[Focura][FocusSessionStore] start failed: \(error)"
                )
            } catch {
                self.lastError = .unknown(
                    message: error.localizedDescription
                )

                print(
                    "[Focura][FocusSessionStore] start failed: \(error)"
                )
            }

            self.isCreating = false
            self.isSynchronizing = false
            self.creationTask = nil
        }

        return true
    }

    func waitForCreation() async {
        guard let creationTask else {
            return
        }

        await creationTask.value
    }

    func pause(at timestamp: Date) async -> Bool {
        guard let current = session,
              current.status == .active
        else {
            return false
        }

        isSynchronizing = true
        lastError = nil
        defer {
            isSynchronizing = false
        }

        do {
            session = try await repository.pause(
                sessionID: current.id,
                startedAt: timestamp
            )

            return true
        } catch let error as APIError {
            lastError = error
            print(
                "[Focura][FocusSessionStore] pause failed: \(error)"
            )
            return false
        } catch {
            lastError = .unknown(
                message: error.localizedDescription
            )

            print(
                "[Focura][FocusSessionStore] pause failed: \(error)"
            )
            return false
        }
    }

    func resume(at timestamp: Date) async -> Bool {
        guard let current = session,
              current.status == .paused
        else {
            return false
        }

        isSynchronizing = true
        lastError = nil
        defer {
            isSynchronizing = false
        }

        do {
            session = try await repository.resume(
                sessionID: current.id,
                endedAt: timestamp
            )

            return true
        } catch let error as APIError {
            lastError = error
            print(
                "[Focura][FocusSessionStore] resume failed: \(error)"
            )
            return false
        } catch {
            lastError = .unknown(
                message: error.localizedDescription
            )

            print(
                "[Focura][FocusSessionStore] resume failed: \(error)"
            )
            return false
        }
    }

    func complete(at timestamp: Date) async -> Bool {
        guard let current = session,
              current.status == .active
        else {
            return false
        }

        isSynchronizing = true
        lastError = nil
        defer {
            isSynchronizing = false
        }

        do {
            session = try await repository.complete(
                sessionID: current.id,
                endedAt: timestamp
            )

            return true
        } catch let error as APIError {
            lastError = error
            print(
                "[Focura][FocusSessionStore] complete failed: \(error)"
            )
            return false
        } catch {
            lastError = .unknown(
                message: error.localizedDescription
            )

            print(
                "[Focura][FocusSessionStore] complete failed: \(error)"
            )
            return false
        }
    }

    func cancel(
        sessionID: Int,
        at timestamp: Date
    ) async -> Bool {
        guard sessionID > 0 else {
            return false
        }

        isSynchronizing = true
        lastError = nil
        defer {
            isSynchronizing = false
        }

        do {
            let cancelled = try await repository.cancel(
                sessionID: sessionID,
                cancelledAt: timestamp
            )

            if session?.id == sessionID {
                session = cancelled
            }

            return true
        } catch let error as APIError {
            lastError = error
            print(
                "[Focura][FocusSessionStore] cancel failed: \(error)"
            )
            return false
        } catch {
            lastError = .unknown(
                message: error.localizedDescription
            )

            print(
                "[Focura][FocusSessionStore] cancel failed: \(error)"
            )
            return false
        }
    }

    func cancel(at timestamp: Date) async -> Bool {
        guard let current = session else {
            return true
        }

        return await cancel(
            sessionID: current.id,
            at: timestamp
        )
    }

    func recordInterruption(
        startedAt: Date,
        endedAt: Date
    ) async -> Bool {
        guard let current = session,
              current.mode == .focus,
              current.status == .active
        else {
            return false
        }

        isSynchronizing = true
        lastError = nil
        defer {
            isSynchronizing = false
        }

        do {
            _ = try await repository.recordInterruption(
                sessionID: current.id,
                startedAt: startedAt,
                endedAt: endedAt
            )

            return true
        } catch let error as APIError {
            lastError = error
            print(
                "[Focura][FocusSessionStore] interruption failed: \(error)"
            )
            return false
        } catch {
            lastError = .unknown(
                message: error.localizedDescription
            )

            print(
                "[Focura][FocusSessionStore] interruption failed: \(error)"
            )
            return false
        }
    }

    func clearCompletedOrCancelledSession() {
        guard let status = session?.status else {
            return
        }

        if status == .completed || status == .cancelled {
            session = nil
            lastError = nil
        }
    }
}
