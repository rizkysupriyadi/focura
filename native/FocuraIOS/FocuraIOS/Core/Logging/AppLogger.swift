import OSLog

enum AppLogger {
    static let app = Logger(
        subsystem: "com.focura.FocuraIOS",
        category: "app"
    )

    static let network = Logger(
        subsystem: "com.focura.FocuraIOS",
        category: "network"
    )

    static let authentication = Logger(
        subsystem: "com.focura.FocuraIOS",
        category: "authentication"
    )

    static let persistence = Logger(
        subsystem: "com.focura.FocuraIOS",
        category: "persistence"
    )
}
