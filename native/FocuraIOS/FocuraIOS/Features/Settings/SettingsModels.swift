import Foundation

enum FocuraAppearance: String, Codable, Sendable, CaseIterable {
    case light
    case dark
    case liquid

    var title: String {
        switch self {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case .liquid:
            return "Liquid"
        }
    }
}

struct FocuraSettingsDefaults: Sendable {
    static let appearance: FocuraAppearance = .light

    static let focusDurationMinutes = 25
    static let shortBreakDurationMinutes = 5
    static let longBreakDurationMinutes = 15

    static let interruptionTrackingEnabled = true
    static let interruptionWarningEnabled = true

    static let completionNotificationEnabled = false
    static let completionSoundEnabled = true
    static let interruptionWarningSoundEnabled = true
}
