import Foundation

struct FocuraWidgetState: Codable, Sendable {
    let mode: Mode
    let status: Status
    let duration: Int
    let remaining: Int
    let startedAt: String?
    let endAt: Double?
    let sessionId: Int?
    let title: String?

    enum Mode: String, Codable, Sendable {
        case focus
        case relax
    }

    enum Status: String, Codable, Sendable {
        case idle
        case running
        case paused
        case completed
    }
}

enum FocuraWidgetStorage {
    static let appGroup = "group.com.focura.shared"
    static let fileName = "focura-widget-state.json"

    static var fileURL: URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroup
        )?.appendingPathComponent(
            fileName,
            isDirectory: false
        )
    }

    static func load() -> FocuraWidgetState? {
        guard let fileURL else {
            return nil
        }

        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }

        return try? JSONDecoder().decode(
            FocuraWidgetState.self,
            from: data
        )
    }

    static func save(_ state: FocuraWidgetState) {
        guard let fileURL else {
            return
        }

        guard let data = try? JSONEncoder().encode(state) else {
            return
        }

        try? data.write(
            to: fileURL,
            options: [.atomic]
        )
    }
}
