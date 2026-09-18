import Foundation

struct HTTPRequest: Sendable {
    let method: String
    let url: URL
    let headers: [String: String]
    let body: Data?
    let timeoutInterval: TimeInterval

    init(
        method: String,
        url: URL,
        headers: [String: String] = [:],
        body: Data? = nil,
        timeoutInterval: TimeInterval = 30
    ) {
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
        self.timeoutInterval = timeoutInterval
    }
}

struct HTTPResponse: Sendable {
    let statusCode: Int
    let data: Data
    let headers: [String: String]
}

protocol HTTPClient: Sendable {
    func send(_ request: HTTPRequest) async throws -> HTTPResponse
}

struct URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    init(
        configuration: URLSessionConfiguration = .default
    ) {
        self.session = URLSession(configuration: configuration)
    }

    func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method
        urlRequest.httpBody = request.body
        urlRequest.timeoutInterval = request.timeoutInterval

        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        do {
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }

            let headers = httpResponse.allHeaderFields.reduce(
                into: [String: String]()
            ) { result, item in
                guard
                    let key = item.key as? String,
                    let value = item.value as? String
                else {
                    return
                }

                result[key] = value
            }

            return HTTPResponse(
                statusCode: httpResponse.statusCode,
                data: data,
                headers: headers
            )
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.network(message: error.localizedDescription)
        }
    }
}
