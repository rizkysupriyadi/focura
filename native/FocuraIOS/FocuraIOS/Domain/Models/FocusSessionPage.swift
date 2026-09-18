import Foundation

struct FocusSessionPage: Codable, Sendable, Equatable {
    let data: [FocusSession]
    let currentPage: Int
    let lastPage: Int
    let perPage: Int
    let total: Int

    enum CodingKeys: String, CodingKey {
        case data
        case currentPage = "current_page"
        case lastPage = "last_page"
        case perPage = "per_page"
        case total
    }

    var hasNextPage: Bool {
        currentPage < lastPage
    }
}
