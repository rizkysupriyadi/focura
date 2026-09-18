import Foundation

enum TimerEngineError: Error, Equatable {
    case invalidTransition(
        from: TimerStatus,
        action: Action
    )

    enum Action: Equatable {
        case start
        case pause
        case resume
        case reset
    }
}

final class TimerEngine {
    private(set) var state: TimerState

    private let clock: any TimerClock

    init(
        mode: TimerMode,
        durationSeconds: Int,
        clock: any TimerClock = SystemTimerClock()
    ) {
        precondition(
            durationSeconds > 0,
            "Timer duration must be greater than zero."
        )

        self.clock = clock

        self.state = TimerState(
            mode: mode,
            durationSeconds: durationSeconds
        )
    }

    func start() throws {
        guard state.status == .idle else {
            throw TimerEngineError.invalidTransition(
                from: state.status,
                action: .start
            )
        }

        let now = clock.now

        let expectedEndAt = now.addingTimeInterval(
            TimeInterval(state.durationSeconds)
        )

        state = TimerState(
            mode: state.mode,
            status: .running,
            durationSeconds: state.durationSeconds,
            startedAt: now,
            activeStartedAt: now,
            expectedEndAt: expectedEndAt,
            pausedAt: nil,
            accumulatedElapsedSeconds: 0
        )
    }

    func pause() throws {
        guard state.status == .running else {
            throw TimerEngineError.invalidTransition(
                from: state.status,
                action: .pause
            )
        }

        let now = clock.now

        guard let activeStartedAt = state.activeStartedAt else {
            throw TimerEngineError.invalidTransition(
                from: state.status,
                action: .pause
            )
        }

        let elapsedSinceResume = max(
            0,
            Int(
                now.timeIntervalSince(
                    activeStartedAt
                )
            )
        )

        let accumulatedElapsed = min(
            state.durationSeconds,
            state.accumulatedElapsedSeconds
                + elapsedSinceResume
        )

        state = TimerState(
            mode: state.mode,
            status: .paused,
            durationSeconds: state.durationSeconds,
            startedAt: state.startedAt,
            activeStartedAt: nil,
            expectedEndAt: state.expectedEndAt,
            pausedAt: now,
            accumulatedElapsedSeconds: accumulatedElapsed
        )
    }

    func resume() throws {
        guard state.status == .paused else {
            throw TimerEngineError.invalidTransition(
                from: state.status,
                action: .resume
            )
        }

        let now = clock.now

        let remainingInterval = remainingInterval(
            at: now
        )

        guard remainingInterval > 0 else {
            state = TimerState(
                mode: state.mode,
                status: .completed,
                durationSeconds: state.durationSeconds,
                startedAt: state.startedAt,
                activeStartedAt: nil,
                expectedEndAt: state.expectedEndAt,
                pausedAt: state.pausedAt,
                accumulatedElapsedSeconds: state.durationSeconds
            )

            return
        }

        let expectedEndAt = now.addingTimeInterval(
            remainingInterval
        )

        state = TimerState(
            mode: state.mode,
            status: .running,
            durationSeconds: state.durationSeconds,
            startedAt: state.startedAt,
            activeStartedAt: now,
            expectedEndAt: expectedEndAt,
            pausedAt: nil,
            accumulatedElapsedSeconds: state.accumulatedElapsedSeconds
        )
    }

    func update() {
        guard state.status == .running else {
            return
        }

        let now = clock.now

        guard let expectedEndAt = state.expectedEndAt else {
            return
        }

        guard now >= expectedEndAt else {
            return
        }

        state = TimerState(
            mode: state.mode,
            status: .completed,
            durationSeconds: state.durationSeconds,
            startedAt: state.startedAt,
            activeStartedAt: nil,
            expectedEndAt: expectedEndAt,
            pausedAt: nil,
            accumulatedElapsedSeconds: state.durationSeconds
        )
    }

    func reset() throws {
        state = TimerState(
            mode: state.mode,
            status: .idle,
            durationSeconds: state.durationSeconds,
            startedAt: nil,
            activeStartedAt: nil,
            expectedEndAt: nil,
            pausedAt: nil,
            accumulatedElapsedSeconds: 0
        )
    }

    func remainingSeconds(
        at date: Date? = nil
    ) -> Int {
        let interval = remainingInterval(
            at: date
        )

        return max(
            0,
            Int(interval)
        )
    }

    func elapsedSeconds(
        at date: Date? = nil
    ) -> Int {
        switch state.status {
        case .idle:
            return 0

        case .paused:
            return min(
                state.durationSeconds,
                state.accumulatedElapsedSeconds
            )

        case .running:
            guard let activeStartedAt = state.activeStartedAt else {
                return state.accumulatedElapsedSeconds
            }

            let referenceDate = date ?? clock.now

            let elapsedSinceResume = max(
                0,
                referenceDate.timeIntervalSince(
                    activeStartedAt
                )
            )

            return min(
                state.durationSeconds,
                state.accumulatedElapsedSeconds
                    + Int(elapsedSinceResume)
            )

        case .completed:
            return state.durationSeconds
        }
    }

    private func remainingInterval(
        at date: Date? = nil
    ) -> TimeInterval {
        switch state.status {
        case .idle:
            return TimeInterval(
                state.durationSeconds
            )

        case .paused:
            guard let expectedEndAt = state.expectedEndAt,
                  let pausedAt = state.pausedAt else {
                return TimeInterval(
                    state.durationSeconds
                )
            }

            return max(
                0,
                expectedEndAt.timeIntervalSince(
                    pausedAt
                )
            )

        case .running:
            guard let expectedEndAt = state.expectedEndAt else {
                return TimeInterval(
                    state.durationSeconds
                )
            }

            let referenceDate = date ?? clock.now

            return max(
                0,
                expectedEndAt.timeIntervalSince(
                    referenceDate
                )
            )

        case .completed:
            return 0
        }
    }
}
