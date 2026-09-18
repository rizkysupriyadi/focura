import Foundation
import SwiftData

@MainActor
final class PersistenceController {
    let container: ModelContainer

    init(inMemory: Bool = false) throws {
        let configuration = ModelConfiguration(
            isStoredInMemoryOnly: inMemory
        )

        do {
            let schema = Schema([])

            container = try ModelContainer(
                for: schema,
                configurations: configuration
            )
        } catch {
            throw PersistenceError.containerCreationFailed(
                message: error.localizedDescription
            )
        }
    }

    static let shared: PersistenceController = {
        do {
            return try PersistenceController()
        } catch {
            fatalError(
                "Unable to initialize Focura persistence: \(error)"
            )
        }
    }()
}
