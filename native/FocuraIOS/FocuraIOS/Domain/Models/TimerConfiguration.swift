import Foundation

struct TimerConfiguration: Codable, Sendable, Equatable {
    let focusDurationSeconds: Int
    let shortBreakDurationSeconds: Int
    let longBreakDurationSeconds: Int

    init(
        focusDurationMinutes: Int,
        shortBreakDurationMinutes: Int,
        longBreakDurationMinutes: Int
    ) {
        precondition(
            focusDurationMinutes > 0,
            "Focus duration must be greater than zero."
        )

        precondition(
            shortBreakDurationMinutes > 0,
            "Short break duration must be greater than zero."
        )

        precondition(
            longBreakDurationMinutes > 0,
            "Long break duration must be greater than zero."
        )

        self.focusDurationSeconds =
            focusDurationMinutes * 60

        self.shortBreakDurationSeconds =
            shortBreakDurationMinutes * 60

        self.longBreakDurationSeconds =
            longBreakDurationMinutes * 60
    }

    init(
        focusDurationSeconds: Int,
        shortBreakDurationSeconds: Int,
        longBreakDurationSeconds: Int
    ) {
        precondition(
            focusDurationSeconds > 0,
            "Focus duration must be greater than zero."
        )

        precondition(
            shortBreakDurationSeconds > 0,
            "Short break duration must be greater than zero."
        )

        precondition(
            longBreakDurationSeconds > 0,
            "Long break duration must be greater than zero."
        )

        self.focusDurationSeconds = focusDurationSeconds
        self.shortBreakDurationSeconds = shortBreakDurationSeconds
        self.longBreakDurationSeconds = longBreakDurationSeconds
    }

    var focusDurationMinutes: Int {
        focusDurationSeconds / 60
    }

    var shortBreakDurationMinutes: Int {
        shortBreakDurationSeconds / 60
    }

    var longBreakDurationMinutes: Int {
        longBreakDurationSeconds / 60
    }

    func durationSeconds(
        for mode: TimerMode
    ) -> Int {
        switch mode {
        case .focus:
            return focusDurationSeconds

        case .relax:
            return shortBreakDurationSeconds
        }
    }
}
