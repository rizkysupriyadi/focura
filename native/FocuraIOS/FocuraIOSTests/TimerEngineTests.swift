import Foundation
import Testing
@testable import FocuraIOS

@Test
func timerEngineStartsIdleWithExpectedInitialState() {
    let engine = TimerEngine(
        mode: .focus,
        durationSeconds: 25 * 60
    )

    #expect(engine.state.mode == .focus)
    #expect(engine.state.status == .idle)
    #expect(engine.state.durationSeconds == 25 * 60)
    #expect(engine.state.startedAt == nil)
    #expect(engine.state.activeStartedAt == nil)
    #expect(engine.state.expectedEndAt == nil)
    #expect(engine.state.pausedAt == nil)
    #expect(engine.state.accumulatedElapsedSeconds == 0)
    #expect(engine.remainingSeconds() == 25 * 60)
    #expect(engine.elapsedSeconds() == 0)
}

@Test
func timerEngineStartsFocusAtInjectedClockTime() throws {
    let start = Date(timeIntervalSince1970: 1_800_000_000)
    let clock = TestTimerClock(now: start)

    let engine = TimerEngine(
        mode: .focus,
        durationSeconds: 25 * 60,
        clock: clock
    )

    try engine.start()

    #expect(engine.state.mode == .focus)
    #expect(engine.state.status == .running)
    #expect(engine.state.startedAt == start)
    #expect(engine.state.activeStartedAt == start)
    #expect(
        engine.state.expectedEndAt
        == start.addingTimeInterval(25 * 60)
    )
    #expect(engine.state.pausedAt == nil)
}

@Test
func timerEngineStartsRelax() throws {
    let start = Date(timeIntervalSince1970: 1_800_000_000)
    let clock = TestTimerClock(now: start)

    let engine = TimerEngine(
        mode: .relax,
        durationSeconds: 5 * 60,
        clock: clock
    )

    try engine.start()

    #expect(engine.state.mode == .relax)
    #expect(engine.state.status == .running)
    #expect(engine.remainingSeconds() == 5 * 60)
}

@Test
func timerEngineCalculatesRemainingFromTimestamp() throws {
    let start = Date(timeIntervalSince1970: 1_800_000_000)
    let clock = TestTimerClock(now: start)

    let engine = TimerEngine(
        mode: .focus,
        durationSeconds: 25 * 60,
        clock: clock
    )

    try engine.start()

    clock.advance(by: 5 * 60)

    #expect(engine.remainingSeconds() == 20 * 60)
    #expect(engine.elapsedSeconds() == 5 * 60)
}

@Test
func timerEnginePausesAndStoresElapsedTime() throws {
    let start = Date(timeIntervalSince1970: 1_800_000_000)
    let clock = TestTimerClock(now: start)

    let engine = TimerEngine(
        mode: .focus,
        durationSeconds: 25 * 60,
        clock: clock
    )

    try engine.start()

    clock.advance(by: 7 * 60 + 12)

    try engine.pause()

    #expect(engine.state.status == .paused)
    #expect(engine.state.pausedAt == clock.now)
    #expect(engine.state.activeStartedAt == nil)
    #expect(engine.state.accumulatedElapsedSeconds == 7 * 60 + 12)
    #expect(engine.remainingSeconds() == 17 * 60 + 48)
}

@Test
func timerEngineResumesUsingRemainingTime() throws {
    let start = Date(timeIntervalSince1970: 1_800_000_000)
    let clock = TestTimerClock(now: start)

    let engine = TimerEngine(
        mode: .focus,
        durationSeconds: 25 * 60,
        clock: clock
    )

    try engine.start()

    clock.advance(by: 10 * 60)
    try engine.pause()

    let remainingBeforeResume = engine.remainingSeconds()

    clock.advance(by: 60 * 60)

    try engine.resume()

    #expect(engine.state.status == .running)
    #expect(engine.state.activeStartedAt == clock.now)
    #expect(engine.remainingSeconds() == remainingBeforeResume)

    clock.advance(by: 30)

    #expect(
        engine.remainingSeconds()
        == remainingBeforeResume - 30
    )
}

@Test
func timerEngineCompletesAtExpectedEndTime() throws {
    let start = Date(timeIntervalSince1970: 1_800_000_000)
    let clock = TestTimerClock(now: start)

    let engine = TimerEngine(
        mode: .focus,
        durationSeconds: 60,
        clock: clock
    )

    try engine.start()

    clock.advance(by: 60)

    engine.update()

    #expect(engine.state.status == .completed)
    #expect(engine.remainingSeconds() == 0)
    #expect(engine.elapsedSeconds() == 60)
    #expect(engine.state.accumulatedElapsedSeconds == 60)
}

@Test
func timerEngineCompletesAfterExpectedEndTime() throws {
    let start = Date(timeIntervalSince1970: 1_800_000_000)
    let clock = TestTimerClock(now: start)

    let engine = TimerEngine(
        mode: .focus,
        durationSeconds: 60,
        clock: clock
    )

    try engine.start()

    clock.advance(by: 75)

    engine.update()

    #expect(engine.state.status == .completed)
    #expect(engine.remainingSeconds() == 0)
    #expect(engine.elapsedSeconds() == 60)
    #expect(engine.state.accumulatedElapsedSeconds == 60)
}

@Test
func timerEngineResetsCompletedTimerToIdle() throws {
    let start = Date(timeIntervalSince1970: 1_800_000_000)
    let clock = TestTimerClock(now: start)

    let engine = TimerEngine(
        mode: .focus,
        durationSeconds: 60,
        clock: clock
    )

    try engine.start()
    clock.advance(by: 60)
    engine.update()

    try engine.reset()

    #expect(engine.state.status == .idle)
    #expect(engine.state.durationSeconds == 60)
    #expect(engine.state.startedAt == nil)
    #expect(engine.state.activeStartedAt == nil)
    #expect(engine.state.expectedEndAt == nil)
    #expect(engine.state.pausedAt == nil)
    #expect(engine.state.accumulatedElapsedSeconds == 0)
    #expect(engine.remainingSeconds() == 60)
}

@Test
func timerEngineRejectsInvalidPause() {
    let engine = TimerEngine(
        mode: .focus,
        durationSeconds: 60
    )

    do {
        try engine.pause()
        Issue.record("Expected pause to fail from idle state.")
    } catch let error as TimerEngineError {
        #expect(
            error
            == .invalidTransition(
                from: .idle,
                action: .pause
            )
        )
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}

@Test
func timerEngineRejectsInvalidResume() {
    let engine = TimerEngine(
        mode: .focus,
        durationSeconds: 60
    )

    do {
        try engine.resume()
        Issue.record("Expected resume to fail from idle state.")
    } catch let error as TimerEngineError {
        #expect(
            error
            == .invalidTransition(
                from: .idle,
                action: .resume
            )
        )
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}

@Test
func timerEngineCompletedTimerCannotPauseOrResume() throws {
    let start = Date(timeIntervalSince1970: 1_800_000_000)
    let clock = TestTimerClock(now: start)

    let engine = TimerEngine(
        mode: .focus,
        durationSeconds: 1,
        clock: clock
    )

    try engine.start()
    clock.advance(by: 1)
    engine.update()

    do {
        try engine.pause()
        Issue.record("Expected completed timer to reject pause.")
    } catch let error as TimerEngineError {
        #expect(
            error
            == .invalidTransition(
                from: .completed,
                action: .pause
            )
        )
    }

    do {
        try engine.resume()
        Issue.record("Expected completed timer to reject resume.")
    } catch let error as TimerEngineError {
        #expect(
            error
            == .invalidTransition(
                from: .completed,
                action: .resume
            )
        )
    }
}

@Test
func timerEngineExcludesPausedTimeFromElapsedTime() throws {
    let start = Date(timeIntervalSince1970: 1_800_000_000)
    let clock = TestTimerClock(now: start)

    let engine = TimerEngine(
        mode: .focus,
        durationSeconds: 20 * 60,
        clock: clock
    )

    try engine.start()

    clock.advance(by: 5 * 60)
    try engine.pause()

    let elapsedBeforePause = engine.elapsedSeconds()

    clock.advance(by: 60 * 60)

    #expect(engine.elapsedSeconds() == elapsedBeforePause)
    #expect(engine.remainingSeconds() == 15 * 60)
}

@Test
func timerEngineUsesDeterministicInjectedClock() throws {
    let start = Date(timeIntervalSince1970: 1_900_000_000)
    let clock = TestTimerClock(now: start)

    let engine = TimerEngine(
        mode: .focus,
        durationSeconds: 10 * 60,
        clock: clock
    )

    try engine.start()

    #expect(engine.state.startedAt == start)

    clock.advance(by: 90)

    #expect(engine.remainingSeconds() == 8 * 60 + 30)
    #expect(engine.elapsedSeconds() == 90)
}

@Test
func timerEngineSupportsOneSecondDuration() throws {
    let start = Date(timeIntervalSince1970: 1_800_000_000)
    let clock = TestTimerClock(now: start)

    let engine = TimerEngine(
        mode: .focus,
        durationSeconds: 1,
        clock: clock
    )

    try engine.start()

    #expect(engine.remainingSeconds() == 1)

    clock.advance(by: 0.999)

    #expect(engine.remainingSeconds() == 0)
    #expect(engine.state.status == .running)

    clock.advance(by: 0.001)

    engine.update()

    #expect(engine.state.status == .completed)
    #expect(engine.remainingSeconds() == 0)
}

@Test
func timerEngineKeepsTimerStateFreeOfClockCalculations() throws {
    let start = Date(timeIntervalSince1970: 1_800_000_000)
    let clock = TestTimerClock(now: start)

    let engine = TimerEngine(
        mode: .focus,
        durationSeconds: 60,
        clock: clock
    )

    try engine.start()

    let stateAtStart = engine.state

    clock.advance(by: 30)

    #expect(stateAtStart.startedAt == start)
    #expect(
        stateAtStart.expectedEndAt
        == start.addingTimeInterval(60)
    )

    #expect(engine.remainingSeconds() == 30)
    #expect(engine.elapsedSeconds() == 30)

    // TimerState is a pure snapshot. Its stored values do not
    // change merely because the clock advances.
    #expect(engine.state == stateAtStart)
}

@Test
func timerEngineRejectsSecondStartWithoutChangingState() throws {
    let start = Date(timeIntervalSince1970: 1_800_000_000)
    let clock = TestTimerClock(now: start)

    let engine = TimerEngine(
        mode: .focus,
        durationSeconds: 60,
        clock: clock
    )

    try engine.start()

    let stateBeforeSecondStart = engine.state

    clock.advance(by: 10)

    do {
        try engine.start()
        Issue.record("Expected second start to fail.")
    } catch let error as TimerEngineError {
        #expect(
            error
            == .invalidTransition(
                from: .running,
                action: .start
            )
        )
    }

    #expect(engine.state == stateBeforeSecondStart)
}

@Test
func timerEngineResetsRunningTimerToIdle() throws {
    let start = Date(timeIntervalSince1970: 1_800_000_000)
    let clock = TestTimerClock(now: start)

    let engine = TimerEngine(
        mode: .focus,
        durationSeconds: 60,
        clock: clock
    )

    try engine.start()
    clock.advance(by: 15)

    try engine.reset()

    #expect(engine.state.status == .idle)
    #expect(engine.state.durationSeconds == 60)
    #expect(engine.state.startedAt == nil)
    #expect(engine.state.activeStartedAt == nil)
    #expect(engine.state.expectedEndAt == nil)
    #expect(engine.state.pausedAt == nil)
    #expect(engine.state.accumulatedElapsedSeconds == 0)
    #expect(engine.remainingSeconds() == 60)
    #expect(engine.elapsedSeconds() == 0)
}

@Test
func timerEngineResetsPausedTimerToIdle() throws {
    let start = Date(timeIntervalSince1970: 1_800_000_000)
    let clock = TestTimerClock(now: start)

    let engine = TimerEngine(
        mode: .focus,
        durationSeconds: 60,
        clock: clock
    )

    try engine.start()
    clock.advance(by: 20)
    try engine.pause()

    clock.advance(by: 30)

    try engine.reset()

    #expect(engine.state.status == .idle)
    #expect(engine.state.durationSeconds == 60)
    #expect(engine.state.startedAt == nil)
    #expect(engine.state.activeStartedAt == nil)
    #expect(engine.state.expectedEndAt == nil)
    #expect(engine.state.pausedAt == nil)
    #expect(engine.state.accumulatedElapsedSeconds == 0)
    #expect(engine.remainingSeconds() == 60)
    #expect(engine.elapsedSeconds() == 0)
}

@Test
func timerEngineCanPauseImmediatelyBeforeDeadline() throws {
    let start = Date(timeIntervalSince1970: 1_800_000_000)
    let clock = TestTimerClock(now: start)

    let engine = TimerEngine(
        mode: .focus,
        durationSeconds: 60,
        clock: clock
    )

    try engine.start()

    clock.advance(by: 59.999)
    try engine.pause()

    #expect(engine.state.status == .paused)
    #expect(engine.state.accumulatedElapsedSeconds == 59)
    #expect(engine.remainingSeconds() == 0)
}

@Test
func timerEngineSupportsMultiplePauseAndResumeCycles() throws {
    let start = Date(timeIntervalSince1970: 1_800_000_000)
    let clock = TestTimerClock(now: start)

    let engine = TimerEngine(
        mode: .focus,
        durationSeconds: 300,
        clock: clock
    )

    try engine.start()

    clock.advance(by: 30)
    try engine.pause()

    #expect(engine.elapsedSeconds() == 30)
    #expect(engine.remainingSeconds() == 270)

    clock.advance(by: 120)

    try engine.resume()

    #expect(engine.elapsedSeconds() == 30)
    #expect(engine.remainingSeconds() == 270)

    clock.advance(by: 45)
    try engine.pause()

    #expect(engine.elapsedSeconds() == 75)
    #expect(engine.remainingSeconds() == 225)

    clock.advance(by: 600)

    try engine.resume()

    #expect(engine.elapsedSeconds() == 75)
    #expect(engine.remainingSeconds() == 225)

    clock.advance(by: 225)
    engine.update()

    #expect(engine.state.status == .completed)
    #expect(engine.elapsedSeconds() == 300)
    #expect(engine.remainingSeconds() == 0)
}

@Test
func timerEngineResumesAsCompletedWhenPausedDeadlineHasPassed() throws {
    let start = Date(timeIntervalSince1970: 1_800_000_000)
    let clock = TestTimerClock(now: start)

    let engine = TimerEngine(
        mode: .focus,
        durationSeconds: 60,
        clock: clock
    )

    try engine.start()

    clock.advance(by: 60)
    try engine.pause()

    #expect(engine.state.status == .paused)
    #expect(engine.remainingSeconds() == 0)

    clock.advance(by: 600)

    try engine.resume()

    #expect(engine.state.status == .completed)
    #expect(engine.elapsedSeconds() == 60)
    #expect(engine.remainingSeconds() == 0)
}

@Test
func timerEngineClampsElapsedAndRemainingAtBounds() throws {
    let start = Date(timeIntervalSince1970: 1_800_000_000)
    let clock = TestTimerClock(now: start)

    let engine = TimerEngine(
        mode: .focus,
        durationSeconds: 60,
        clock: clock
    )

    try engine.start()

    clock.advance(by: 120)

    #expect(engine.remainingSeconds() == 0)
    #expect(engine.elapsedSeconds() == 60)

    engine.update()

    #expect(engine.state.status == .completed)
    #expect(engine.remainingSeconds() == 0)
    #expect(engine.elapsedSeconds() == 60)
}

@Test
func timerEngineInvalidTransitionsDoNotMutateState() throws {
    let start = Date(timeIntervalSince1970: 1_800_000_000)
    let clock = TestTimerClock(now: start)

    let engine = TimerEngine(
        mode: .relax,
        durationSeconds: 120,
        clock: clock
    )

    let initialState = engine.state

    do {
        try engine.pause()
        Issue.record("Expected pause to fail from idle.")
    } catch let error as TimerEngineError {
        #expect(
            error
            == .invalidTransition(
                from: .idle,
                action: .pause
            )
        )
    }

    #expect(engine.state == initialState)

    do {
        try engine.resume()
        Issue.record("Expected resume to fail from idle.")
    } catch let error as TimerEngineError {
        #expect(
            error
            == .invalidTransition(
                from: .idle,
                action: .resume
            )
        )
    }

    #expect(engine.state == initialState)

    try engine.start()

    let runningState = engine.state

    do {
        try engine.resume()
        Issue.record("Expected resume to fail from running.")
    } catch let error as TimerEngineError {
        #expect(
            error
            == .invalidTransition(
                from: .running,
                action: .resume
            )
        )
    }

    #expect(engine.state == runningState)
}

@Test
func timerEngineFocusAndRelaxShareTheSameLifecycleContract() throws {
    let start = Date(timeIntervalSince1970: 1_800_000_000)

    for mode in TimerMode.allCases {
        let clock = TestTimerClock(now: start)

        let engine = TimerEngine(
            mode: mode,
            durationSeconds: 60,
            clock: clock
        )

        #expect(engine.state.mode == mode)
        #expect(engine.state.status == .idle)

        try engine.start()

        #expect(engine.state.status == .running)

        clock.advance(by: 20)
        try engine.pause()

        #expect(engine.state.status == .paused)
        #expect(engine.elapsedSeconds() == 20)

        clock.advance(by: 100)

        try engine.resume()

        #expect(engine.state.status == .running)
        #expect(engine.remainingSeconds() == 40)

        clock.advance(by: 40)
        engine.update()

        #expect(engine.state.status == .completed)
        #expect(engine.elapsedSeconds() == 60)
        #expect(engine.remainingSeconds() == 0)
    }
}

@Test
func timerEngineMaintainsTimestampConsistencyAcrossPauseAndResume() throws {
    let start = Date(timeIntervalSince1970: 1_800_000_000)
    let clock = TestTimerClock(now: start)

    let engine = TimerEngine(
        mode: .focus,
        durationSeconds: 30 * 60,
        clock: clock
    )

    try engine.start()

    #expect(engine.state.startedAt == start)

    clock.advance(by: 8 * 60)
    try engine.pause()

    let firstPause = clock.now
    let firstExpectedEnd = engine.state.expectedEndAt

    #expect(engine.state.startedAt == start)
    #expect(engine.state.activeStartedAt == nil)
    #expect(engine.state.pausedAt == firstPause)
    #expect(firstExpectedEnd == start.addingTimeInterval(30 * 60))

    clock.advance(by: 15 * 60)

    try engine.resume()

    #expect(engine.state.startedAt == start)
    #expect(engine.state.activeStartedAt == clock.now)
    #expect(engine.state.pausedAt == nil)

    let expectedRemaining = 22 * 60

    #expect(engine.remainingSeconds() == expectedRemaining)
    #expect(
        engine.state.expectedEndAt
        == clock.now.addingTimeInterval(
            TimeInterval(expectedRemaining)
        )
    )
}

@Test
func timerConfigurationMapsSettingsMinutesToSeconds() {
    let configuration = TimerConfiguration(
        focusDurationMinutes: 25,
        shortBreakDurationMinutes: 5,
        longBreakDurationMinutes: 15
    )

    #expect(configuration.focusDurationSeconds == 1_500)
    #expect(configuration.shortBreakDurationSeconds == 300)
    #expect(configuration.longBreakDurationSeconds == 900)

    #expect(configuration.focusDurationMinutes == 25)
    #expect(configuration.shortBreakDurationMinutes == 5)
    #expect(configuration.longBreakDurationMinutes == 15)
}

@Test
func timerConfigurationSelectsDurationForEachTimerMode() {
    let configuration = TimerConfiguration(
        focusDurationMinutes: 50,
        shortBreakDurationMinutes: 10,
        longBreakDurationMinutes: 20
    )

    #expect(
        configuration.durationSeconds(for: .focus)
        == 3_000
    )

    #expect(
        configuration.durationSeconds(for: .relax)
        == 600
    )
}

@Test
func timerConfigurationCanCreateIndependentTimerEngines() throws {
    let configuration = TimerConfiguration(
        focusDurationMinutes: 25,
        shortBreakDurationMinutes: 5,
        longBreakDurationMinutes: 15
    )

    let focusEngine = TimerEngine(
        mode: .focus,
        durationSeconds: configuration.durationSeconds(
            for: .focus
        )
    )

    let relaxEngine = TimerEngine(
        mode: .relax,
        durationSeconds: configuration.durationSeconds(
            for: .relax
        )
    )

    #expect(focusEngine.state.durationSeconds == 1_500)
    #expect(relaxEngine.state.durationSeconds == 300)

    try focusEngine.start()

    #expect(focusEngine.state.durationSeconds == 1_500)
    #expect(relaxEngine.state.durationSeconds == 300)
}

@Test
func timerConfigurationSnapshotDoesNotChangeWhenSourceValuesChange() {
    var focusDurationMinutes = 25
    var shortBreakDurationMinutes = 5
    var longBreakDurationMinutes = 15

    let configuration = TimerConfiguration(
        focusDurationMinutes: focusDurationMinutes,
        shortBreakDurationMinutes: shortBreakDurationMinutes,
        longBreakDurationMinutes: longBreakDurationMinutes
    )

    focusDurationMinutes = 50
    shortBreakDurationMinutes = 10
    longBreakDurationMinutes = 30

    #expect(configuration.focusDurationMinutes == 25)
    #expect(configuration.shortBreakDurationMinutes == 5)
    #expect(configuration.longBreakDurationMinutes == 15)
}
