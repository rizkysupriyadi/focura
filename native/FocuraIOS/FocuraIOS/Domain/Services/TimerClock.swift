import Foundation

protocol TimerClock: Sendable {
    var now: Date { get }
}

struct SystemTimerClock: TimerClock {
    var now: Date {
        Date()
    }
}

final class TestTimerClock: TimerClock, @unchecked Sendable {
    private var currentDate: Date

    init(
        now: Date
    ) {
        self.currentDate = now
    }

    var now: Date {
        currentDate
    }

    func advance(
        by interval: TimeInterval
    ) {
        currentDate = currentDate.addingTimeInterval(interval)
    }

    func set(
        now date: Date
    ) {
        currentDate = date
    }
}
