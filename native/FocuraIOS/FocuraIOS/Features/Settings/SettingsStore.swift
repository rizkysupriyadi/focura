import Foundation

@MainActor
final class SettingsStore: ObservableObject {
    @Published private(set) var appearance: FocuraAppearance
    @Published private(set) var focusDurationMinutes: Int
    @Published private(set) var shortBreakDurationMinutes: Int
    @Published private(set) var longBreakDurationMinutes: Int

    @Published private(set) var interruptionTrackingEnabled: Bool
    @Published private(set) var interruptionWarningEnabled: Bool

    @Published private(set) var completionNotificationEnabled: Bool
    @Published private(set) var completionSoundEnabled: Bool
    @Published private(set) var interruptionWarningSoundEnabled: Bool

    private let defaults: UserDefaults

    private enum Key {
        static let appearance = "focura.settings.appearance"
        static let focusDurationMinutes = "focura.settings.focusDurationMinutes"
        static let shortBreakDurationMinutes = "focura.settings.shortBreakDurationMinutes"
        static let longBreakDurationMinutes = "focura.settings.longBreakDurationMinutes"
        static let interruptionTrackingEnabled = "focura.settings.interruptionTrackingEnabled"
        static let interruptionWarningEnabled = "focura.settings.interruptionWarningEnabled"
        static let completionNotificationEnabled = "focura.settings.completionNotificationEnabled"
        static let completionSoundEnabled = "focura.settings.completionSoundEnabled"
        static let interruptionWarningSoundEnabled = "focura.settings.interruptionWarningSoundEnabled"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        self.appearance =
            FocuraAppearance(
                rawValue: defaults.string(forKey: Key.appearance) ?? ""
            ) ?? FocuraSettingsDefaults.appearance

        self.focusDurationMinutes =
            Self.integer(
                defaults,
                key: Key.focusDurationMinutes,
                fallback: FocuraSettingsDefaults.focusDurationMinutes,
                minimum: 1,
                maximum: 180
            )

        self.shortBreakDurationMinutes =
            Self.integer(
                defaults,
                key: Key.shortBreakDurationMinutes,
                fallback: FocuraSettingsDefaults.shortBreakDurationMinutes,
                minimum: 1,
                maximum: 60
            )

        self.longBreakDurationMinutes =
            Self.integer(
                defaults,
                key: Key.longBreakDurationMinutes,
                fallback: FocuraSettingsDefaults.longBreakDurationMinutes,
                minimum: 1,
                maximum: 120
            )

        self.interruptionTrackingEnabled =
            defaults.object(forKey: Key.interruptionTrackingEnabled)
            as? Bool
            ?? FocuraSettingsDefaults.interruptionTrackingEnabled

        self.interruptionWarningEnabled =
            defaults.object(forKey: Key.interruptionWarningEnabled)
            as? Bool
            ?? FocuraSettingsDefaults.interruptionWarningEnabled

        self.completionNotificationEnabled =
            defaults.object(forKey: Key.completionNotificationEnabled)
            as? Bool
            ?? FocuraSettingsDefaults.completionNotificationEnabled

        self.completionSoundEnabled =
            defaults.object(forKey: Key.completionSoundEnabled)
            as? Bool
            ?? FocuraSettingsDefaults.completionSoundEnabled

        self.interruptionWarningSoundEnabled =
            defaults.object(forKey: Key.interruptionWarningSoundEnabled)
            as? Bool
            ?? FocuraSettingsDefaults.interruptionWarningSoundEnabled
    }

    func setAppearance(_ value: FocuraAppearance) {
        appearance = value
        defaults.set(value.rawValue, forKey: Key.appearance)
    }

    func setFocusDurationMinutes(_ value: Int) {
        guard (1...180).contains(value) else {
            return
        }

        focusDurationMinutes = value
        defaults.set(value, forKey: Key.focusDurationMinutes)
    }

    func setShortBreakDurationMinutes(_ value: Int) {
        guard (1...60).contains(value) else {
            return
        }

        shortBreakDurationMinutes = value
        defaults.set(value, forKey: Key.shortBreakDurationMinutes)
    }

    func setLongBreakDurationMinutes(_ value: Int) {
        guard (1...120).contains(value) else {
            return
        }

        longBreakDurationMinutes = value
        defaults.set(value, forKey: Key.longBreakDurationMinutes)
    }

    func setInterruptionTrackingEnabled(_ value: Bool) {
        interruptionTrackingEnabled = value
        defaults.set(value, forKey: Key.interruptionTrackingEnabled)
    }

    func setInterruptionWarningEnabled(_ value: Bool) {
        interruptionWarningEnabled = value
        defaults.set(value, forKey: Key.interruptionWarningEnabled)
    }

    func setCompletionNotificationEnabled(_ value: Bool) {
        completionNotificationEnabled = value
        defaults.set(value, forKey: Key.completionNotificationEnabled)
    }

    func setCompletionSoundEnabled(_ value: Bool) {
        completionSoundEnabled = value
        defaults.set(value, forKey: Key.completionSoundEnabled)
    }

    func setInterruptionWarningSoundEnabled(_ value: Bool) {
        interruptionWarningSoundEnabled = value
        defaults.set(value, forKey: Key.interruptionWarningSoundEnabled)
    }

    func reset() {
        appearance = FocuraSettingsDefaults.appearance
        focusDurationMinutes = FocuraSettingsDefaults.focusDurationMinutes
        shortBreakDurationMinutes = FocuraSettingsDefaults.shortBreakDurationMinutes
        longBreakDurationMinutes = FocuraSettingsDefaults.longBreakDurationMinutes

        interruptionTrackingEnabled =
            FocuraSettingsDefaults.interruptionTrackingEnabled
        interruptionWarningEnabled =
            FocuraSettingsDefaults.interruptionWarningEnabled

        completionNotificationEnabled =
            FocuraSettingsDefaults.completionNotificationEnabled
        completionSoundEnabled =
            FocuraSettingsDefaults.completionSoundEnabled
        interruptionWarningSoundEnabled =
            FocuraSettingsDefaults.interruptionWarningSoundEnabled

        defaults.removeObject(forKey: Key.appearance)
        defaults.removeObject(forKey: Key.focusDurationMinutes)
        defaults.removeObject(forKey: Key.shortBreakDurationMinutes)
        defaults.removeObject(forKey: Key.longBreakDurationMinutes)
        defaults.removeObject(forKey: Key.interruptionTrackingEnabled)
        defaults.removeObject(forKey: Key.interruptionWarningEnabled)
        defaults.removeObject(forKey: Key.completionNotificationEnabled)
        defaults.removeObject(forKey: Key.completionSoundEnabled)
        defaults.removeObject(forKey: Key.interruptionWarningSoundEnabled)
    }

    private static func integer(
        _ defaults: UserDefaults,
        key: String,
        fallback: Int,
        minimum: Int,
        maximum: Int
    ) -> Int {
        guard defaults.object(forKey: key) != nil else {
            return fallback
        }

        let value = defaults.integer(forKey: key)

        guard (minimum...maximum).contains(value) else {
            return fallback
        }

        return value
    }
}

extension SettingsStore {
    var timerConfiguration: TimerConfiguration {
        TimerConfiguration(
            focusDurationMinutes: focusDurationMinutes,
            shortBreakDurationMinutes: shortBreakDurationMinutes,
            longBreakDurationMinutes: longBreakDurationMinutes
        )
    }
}
