import Foundation

@MainActor
final class AppContainer {
    let configuration: AppConfiguration
    let httpClient: any HTTPClient
    let apiClient: APIClient
    let authSessionStore: AuthSessionStore
    let authRepository: any AuthRepository
    let authenticationState: AuthenticationState
    let visitorIdentityStore: VisitorIdentityStore
    let focusSessionRepository: any FocusSessionRepository
    let focusSessionStore: FocusSessionStore

    init(
        configuration: AppConfiguration = AppConfiguration()
    ) {
        self.configuration = configuration

        let httpClient = URLSessionHTTPClient(
            configuration: .default
        )

        let apiClient = APIClient(
            configuration: configuration,
            httpClient: httpClient
        )

        let authSessionStore = AuthSessionStore()

        let authRepository = RemoteAuthRepository(
            apiClient: apiClient,
            sessionStore: authSessionStore
        )

        self.httpClient = httpClient
        self.apiClient = apiClient
        self.authSessionStore = authSessionStore
        self.authRepository = authRepository
        self.authenticationState = AuthenticationState(
            repository: authRepository
        )

        let visitorIdentityStore = VisitorIdentityStore()

        let focusSessionRepository = RemoteFocusSessionRepository(
            apiClient: apiClient,
            authSessionStore: authSessionStore,
            visitorIdentityStore: visitorIdentityStore
        )

        self.visitorIdentityStore = visitorIdentityStore
        self.focusSessionRepository = focusSessionRepository
        self.focusSessionStore = FocusSessionStore(
            repository: focusSessionRepository
        )
    }
}
