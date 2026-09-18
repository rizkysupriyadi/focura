import Foundation
import Observation

@MainActor
@Observable
final class SessionsStore {
    private(set) var sessions: [FocusSession] = []
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var lastError: APIError?

    var selectedMode: TimerMode?
    var selectedStatus: FocusSessionStatus?

    private let repository: any FocusSessionRepository
    private let perPage = 20
    private var currentPage = 0
    private var lastPage = 1

    init(repository: any FocusSessionRepository) {
        self.repository = repository
    }

    var hasNextPage: Bool {
        currentPage < lastPage
    }

    func load() async {
        guard !isLoading else { return }

        isLoading = true
        isLoadingMore = false
        lastError = nil

        do {
            let page = try await repository.list(
                page: 1,
                perPage: perPage,
                mode: selectedMode,
                status: selectedStatus
            )

            sessions = page.data
            currentPage = page.currentPage
            lastPage = page.lastPage
        } catch let error as APIError {
            lastError = error
        } catch {
            lastError = .unknown(message: error.localizedDescription)
        }

        isLoading = false
    }

    func refresh() async {
        await load()
    }

    func loadMoreIfNeeded(currentItem: FocusSession?) async {
        guard
            let currentItem,
            hasNextPage,
            !isLoading,
            !isLoadingMore,
            let index = sessions.firstIndex(where: { $0.id == currentItem.id }),
            index >= sessions.count - 5
        else {
            return
        }

        await loadMore()
    }

    func loadMore() async {
        guard hasNextPage, !isLoading, !isLoadingMore else { return }

        isLoadingMore = true
        lastError = nil

        do {
            let page = try await repository.list(
                page: currentPage + 1,
                perPage: perPage,
                mode: selectedMode,
                status: selectedStatus
            )

            let existingIDs = Set(sessions.map(\.id))
            sessions.append(contentsOf: page.data.filter {
                !existingIDs.contains($0.id)
            })

            currentPage = page.currentPage
            lastPage = page.lastPage
        } catch let error as APIError {
            lastError = error
        } catch {
            lastError = .unknown(message: error.localizedDescription)
        }

        isLoadingMore = false
    }

    func applyFilters() async {
        await load()
    }

    func clearError() {
        lastError = nil
    }
}
