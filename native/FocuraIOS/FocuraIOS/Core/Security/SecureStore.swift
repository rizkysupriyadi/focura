import Foundation

protocol SecureStore: Sendable {
    func set(_ value: String, forKey key: String) throws
    func string(forKey key: String) throws -> String?
    func delete(forKey key: String) throws
}
