import Foundation

enum AppEnvironment: Sendable, Equatable {
    case development
    case production

    static var current: Self {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
}

struct AppConfiguration: Sendable, Equatable {
    let environment: AppEnvironment
    let apiBaseURL: URL
    let requestTimeout: TimeInterval
    let resourceTimeout: TimeInterval

    init(
        environment: AppEnvironment = .current,
        apiBaseURL: URL? = nil,
        requestTimeout: TimeInterval = 30,
        resourceTimeout: TimeInterval = 60
    ) {
        self.environment = environment
        self.apiBaseURL = apiBaseURL ?? Self.defaultAPIBaseURL(for: environment)
        self.requestTimeout = requestTimeout
        self.resourceTimeout = resourceTimeout
    }

    private static func defaultAPIBaseURL(for environment: AppEnvironment) -> URL {
        switch environment {
        case .development:
            return URL(string: "http://127.0.0.1:8000/api/v1")!
        case .production:
            return URL(string: "https://focura.app/api/v1")!
        }
    }
}
