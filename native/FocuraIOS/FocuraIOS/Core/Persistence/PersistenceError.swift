import Foundation

enum PersistenceError: Error, Sendable, Equatable {
    case containerCreationFailed(message: String)
}
