import Foundation

enum APIError: Error, Sendable, Equatable {
    case invalidURL
    case invalidResponse
    case unauthorized
    case forbidden
    case notFound
    case conflict
    case validation(message: String)
    case server(statusCode: Int)
    case network(message: String)
    case decoding(message: String)
    case unknown(message: String)

    var isAuthenticationFailure: Bool {
        switch self {
        case .unauthorized:
            return true
        default:
            return false
        }
    }
}
