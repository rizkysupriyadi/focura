import SwiftUI

@main
struct FocuraIOSApp: App {
    @State private var container: AppContainer

    init() {
        let container = AppContainer()
        _container = State(initialValue: container)
    }

    var body: some Scene {
        WindowGroup {
            AppRootView(
                authenticationState: container.authenticationState,
                focusSessionStore: container.focusSessionStore
            )
            .environment(container.authenticationState)
        }
    }
}

private struct AppRootView: View {
    @Bindable var authenticationState: AuthenticationState
    let focusSessionStore: FocusSessionStore

    var body: some View {
        ZStack {
            FocuraColors.surface
                .ignoresSafeArea()

            Group {
                switch authenticationState.status {
                case .restoring:
                    AuthenticationRestoringView()

                case .authenticated:
                    MainAppView(
                        user: authenticatedUser,
                        focusSessionStore: focusSessionStore
                    )

                case .unauthenticated:
                    AuthFlowView(
                        authenticationState: authenticationState
                    )
                }
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
        }
        .task {
            await authenticationState.restoreSession()
        }
    }

    private var authenticatedUser: AuthUser {
        guard case let .authenticated(user) = authenticationState.status else {
            preconditionFailure(
                "Authenticated user requested while authentication state is not authenticated."
            )
        }

        return user
    }
}

private struct AuthenticationRestoringView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()

            Text("Restoring your session…")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Restoring your session")
    }
}

private struct AuthFlowView: View {
    @Bindable var authenticationState: AuthenticationState

    @State private var screen: Screen = .login

    private enum Screen {
        case login
        case register
    }

    var body: some View {
        Group {
            switch screen {
            case .login:
                LoginView(
                    authenticationState: authenticationState,
                    onRegister: {
                        authenticationState.clearError()
                        screen = .register
                    }
                )

            case .register:
                RegisterView(
                    authenticationState: authenticationState,
                    onLogin: {
                        authenticationState.clearError()
                        screen = .login
                    }
                )
            }
        }
    }
}

private struct MainAppView: View {
    let user: AuthUser
    let focusSessionStore: FocusSessionStore

    var body: some View {
        ContentView(
            focusSessionStore: focusSessionStore,
            user: user
        )
    }
}
