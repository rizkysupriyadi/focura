import Foundation

struct FocusSessionListResponse: Codable, Sendable, Equatable {
    let data: [FocusSession]
    let links: Links
    let meta: Meta

    struct Links: Codable, Sendable, Equatable {
        let first: String?
        let last: String?
        let prev: String?
        let next: String?
    }

    struct Meta: Codable, Sendable, Equatable {
        let currentPage: Int
        let from: Int?
        let lastPage: Int
        let links: [MetaLink]
        let path: String?
        let perPage: Int
        let to: Int?
        let total: Int

        enum CodingKeys: String, CodingKey {
            case currentPage = "current_page"
            case from
            case lastPage = "last_page"
            case links
            case path
            case perPage = "per_page"
            case to
            case total
        }
    }

    struct MetaLink: Codable, Sendable, Equatable {
        let url: String?
        let label: String
        let active: Bool
    }

    func page() -> FocusSessionPage {
        FocusSessionPage(
            data: data,
            currentPage: meta.currentPage,
            lastPage: meta.lastPage,
            perPage: meta.perPage,
            total: meta.total
        )
    }
}
