import Foundation

actor VisitorIdentityStore {
    private let secureStore: any SecureStore
    private let key = "focura.visitor.id"

    init(
        secureStore: any SecureStore = KeychainStore()
    ) {
        self.secureStore = secureStore
    }

    func visitorID() throws -> String {
        if let existing = try secureStore.string(forKey: key),
           Self.isValidUUIDv4(existing) {
            return existing
        }

        let value = UUID().uuidString.lowercased()
        try secureStore.set(value, forKey: key)
        return value
    }

    private static func isValidUUIDv4(_ value: String) -> Bool {
        value.range(
            of: #"^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$"#,
            options: [.regularExpression, .caseInsensitive]
        ) != nil
    }
}
