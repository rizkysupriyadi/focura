import Foundation

struct FocuraWidgetState: Codable, Sendable {
    let mode: Mode
    let status: Status
    let duration: TimeInterval
    let remaining: TimeInterval
    let startedAt: String?
    let endAt: Date?
    let sessionId: Int?
    let title: String?

    enum CodingKeys: String, CodingKey {
        case mode
        case status
        case duration
        case remaining
        case startedAt
        case endAt
        case sessionId
        case title
    }

    init(
        mode: Mode,
        status: Status,
        duration: TimeInterval,
        remaining: TimeInterval,
        startedAt: String?,
        endAt: Date?,
        sessionId: Int?,
        title: String?
    ) {
        self.mode = mode
        self.status = status
        self.duration = duration
        self.remaining = remaining
        self.startedAt = startedAt
        self.endAt = endAt
        self.sessionId = sessionId
        self.title = title
    }

    init(
        from decoder: Decoder
    ) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        mode = try container.decode(
            Mode.self,
            forKey: .mode
        )

        status = try container.decode(
            Status.self,
            forKey: .status
        )

        duration = try container.decode(
            TimeInterval.self,
            forKey: .duration
        )

        remaining = try container.decode(
            TimeInterval.self,
            forKey: .remaining
        )

        startedAt = try container.decodeIfPresent(
            String.self,
            forKey: .startedAt
        )

        if let milliseconds = try container.decodeIfPresent(
            Double.self,
            forKey: .endAt
        ) {
            endAt = Date(
                timeIntervalSince1970:
                    milliseconds / 1000
            )
        } else {
            endAt = nil
        }

        sessionId = try container.decodeIfPresent(
            Int.self,
            forKey: .sessionId
        )

        title = try container.decodeIfPresent(
            String.self,
            forKey: .title
        )
    }

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
    static let appGroup =
        "group.com.focura.shared"

    static let fileName =
        "focura-widget-state.json"

    static var fileURL: URL? {
        FileManager.default
            .containerURL(
                forSecurityApplicationGroupIdentifier:
                    appGroup
            )?
            .appendingPathComponent(
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

    static func save(
        _ state: FocuraWidgetState
    ) {
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
