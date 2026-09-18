import Foundation

struct TimerDurationSelection: Codable, Sendable, Equatable {
    static let minimumMinutes = 1
    static let maximumMinutes = 180

    let configuredMinutes: Int
    private(set) var selectedMinutes: Int
    private(set) var usesCustom: Bool

    init(
        configuredMinutes: Int,
        selectedMinutes: Int? = nil,
        usesCustom: Bool = false
    ) {
        let configured = Self.clamp(configuredMinutes)

        self.configuredMinutes = configured
        self.usesCustom = usesCustom

        if usesCustom {
            self.selectedMinutes = Self.clamp(
                selectedMinutes ?? configured
            )
        } else {
            self.selectedMinutes = Self.clamp(
                selectedMinutes ?? configured
            )
        }
    }

    mutating func selectPreset(_ minutes: Int) {
        selectedMinutes = Self.clamp(minutes)
        usesCustom = false
    }

    mutating func selectCustom(_ minutes: Int) {
        selectedMinutes = Self.clamp(minutes)
        usesCustom = true
    }

    mutating func updateCustom(_ minutes: Int) {
        guard usesCustom else {
            return
        }

        selectedMinutes = Self.clamp(minutes)
    }

    private static func clamp(_ minutes: Int) -> Int {
        min(
            maximumMinutes,
            max(minimumMinutes, minutes)
        )
    }
}
