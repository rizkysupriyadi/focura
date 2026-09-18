import Foundation

struct APIClient: Sendable {
    private let configuration: AppConfiguration
    private let httpClient: any HTTPClient

    init(
        configuration: AppConfiguration,
        httpClient: any HTTPClient
    ) {
        self.configuration = configuration
        self.httpClient = httpClient
    }

    func request(
        path: String,
        method: String = "GET",
        headers: [String: String] = [:],
        body: Data? = nil
    ) async throws -> HTTPResponse {
        guard let url = makeURL(path: path) else {
            throw APIError.invalidURL
        }

        var requestHeaders = headers
        requestHeaders["Accept"] = "application/json"

        let request = HTTPRequest(
            method: method,
            url: url,
            headers: requestHeaders,
            body: body,
            timeoutInterval: configuration.requestTimeout
        )


        do {
            let response = try await httpClient.send(request)
            switch response.statusCode {
        case 200...299:
            return response
        case 401:
            throw APIError.unauthorized
        case 403:
            throw APIError.forbidden
        case 404:
            throw APIError.notFound
        case 409:
            throw APIError.conflict
        case 422:
            throw APIError.validation(
                message: String(
                    data: response.data,
                    encoding: .utf8
                ) ?? "Validation failed."
            )
        case 500...599:
            throw APIError.server(statusCode: response.statusCode)
            default:
                throw APIError.unknown(
                    message: "HTTP \(response.statusCode)"
                )
            }
        }
    }

    private func makeURL(path: String) -> URL? {
        let normalizedPath = path.hasPrefix("/")
            ? String(path.dropFirst())
            : path

        return configuration.apiBaseURL.appendingPathComponent(
            normalizedPath
        )
    }
}
