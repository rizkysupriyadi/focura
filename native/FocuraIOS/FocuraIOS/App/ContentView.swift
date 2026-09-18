import SwiftUI

struct ContentView: View {
    let focusSessionStore: FocusSessionStore
    let user: AuthUser

    var body: some View {
        TabView {
            NavigationStack {
                FocusHomeView(focusSessionStore: focusSessionStore)
            }
            .tabItem {
                Label(
                    "Focus",
                    systemImage: "scope"
                )
            }

            NavigationStack {
                SessionsRootView()
            }
            .tabItem {
                Label(
                    "Sessions",
                    systemImage: "clock"
                )
            }

            NavigationStack {
                InsightsRootView()
            }
            .tabItem {
                Label(
                    "Insights",
                    systemImage: "chart.bar"
                )
            }

            NavigationStack {
                SettingsRootView(user: user)
            }
            .tabItem {
                Label(
                    "Settings",
                    systemImage: "gearshape"
                )
            }
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .tint(FocuraColors.primary)
        .background(
            FocuraColors.surface
                .ignoresSafeArea()
        )
    }
}

private struct SessionsRootView: View {
    var body: some View {
        PlaceholderRootView(
            title: "Sessions",
            subtitle: "Your focus history will appear here."
        )
    }
}

private struct InsightsRootView: View {
    var body: some View {
        PlaceholderRootView(
            title: "Insights",
            subtitle: "Your focus patterns will appear here."
        )
    }
}

private struct SettingsRootView: View {
    let user: AuthUser

    var body: some View {
        SettingsView(user: user)
    }
}

private struct PlaceholderRootView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: FocuraSpacing.small
        ) {
            Text(title)
                .font(FocuraTypography.pageTitle)
                .foregroundStyle(FocuraColors.textPrimary)

            Text(subtitle)
                .font(FocuraTypography.body)
                .foregroundStyle(FocuraColors.textSecondary)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
        .padding(FocuraSpacing.page)
        .background(FocuraColors.surface)
        .navigationTitle(title)
    }
}

#Preview {
    ContentView(
        focusSessionStore: FocusSessionStore(
            repository: PreviewContentFocusSessionRepository()
        ),
        user: AuthUser(
            id: 1,
            name: "Preview User",
            email: "preview@focura.app",
            emailVerifiedAt: nil,
            createdAt: nil
        )
    )
}

private struct PreviewContentFocusSessionRepository: FocusSessionRepository {
    func create(
        mode: TimerMode,
        title: String?,
        plannedDurationSeconds: Int,
        startedAt: Date
    ) async throws -> FocusSession {
        FocusSession(
            id: 1,
            userID: nil,
            visitorID: nil,
            mode: mode,
            title: title,
            plannedDurationSeconds: plannedDurationSeconds,
            actualDurationSeconds: 0,
            focusedDurationSeconds: 0,
            interruptedDurationSeconds: 0,
            interruptionCount: 0,
            focusIntegrity: nil,
            status: .active,
            startedAt: startedAt,
            endedAt: nil,
            interruptions: [],
            createdAt: startedAt,
            updatedAt: startedAt
        )
    }

    func pause(
        sessionID: Int,
        startedAt: Date
    ) async throws -> FocusSession {
        fatalError("Preview only")
    }

    func resume(
        sessionID: Int,
        endedAt: Date
    ) async throws -> FocusSession {
        fatalError("Preview only")
    }

    func complete(
        sessionID: Int,
        endedAt: Date
    ) async throws -> FocusSession {
        fatalError("Preview only")
    }

    func cancel(
        sessionID: Int,
        cancelledAt: Date
    ) async throws -> FocusSession {
        fatalError("Preview only")
    }

    func recordInterruption(
        sessionID: Int,
        startedAt: Date,
        endedAt: Date
    ) async throws -> FocusSessionInterruption {
        fatalError("Preview only")
    }
}
