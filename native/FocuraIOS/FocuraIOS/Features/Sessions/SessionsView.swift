import SwiftUI

struct SessionsView: View {
    @State private var store: SessionsStore
    @State private var selectedSession: FocusSession?

    init(repository: any FocusSessionRepository) {
        _store = State(
            initialValue: SessionsStore(repository: repository)
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if store.isLoading && store.sessions.isEmpty {
                    ProgressView("Loading sessions…")
                } else if let error = store.lastError, store.sessions.isEmpty {
                    errorView(error)
                } else if store.sessions.isEmpty {
                    emptyView
                } else {
                    sessionList
                }
            }
            .navigationTitle("Sessions")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        modeFilterMenu
                        Divider()
                        statusFilterMenu
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel("Filter sessions")
                }
            }
            .task {
                if store.sessions.isEmpty {
                    await store.load()
                }
            }
            .refreshable {
                await store.refresh()
            }
            .sheet(item: $selectedSession) { session in
                SessionDetailView(session: session)
            }
        }
    }

    private var sessionList: some View {
        List {
            ForEach(store.sessions) { session in
                Button {
                    selectedSession = session
                } label: {
                    SessionRowView(session: session)
                }
                .buttonStyle(.plain)
                .task {
                    await store.loadMoreIfNeeded(currentItem: session)
                }
            }

            if store.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
    }

    private var emptyView: some View {
        ContentUnavailableView(
            "No Sessions",
            systemImage: "clock",
            description: Text(
                "Completed and active focus sessions will appear here."
            )
        )
    }

    private func errorView(_ error: APIError) -> some View {
        ContentUnavailableView {
            Label("Unable to Load Sessions", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.userMessage)
        } actions: {
            Button("Try Again") {
                Task {
                    await store.load()
                }
            }
        }
    }

    private var modeFilterMenu: some View {
        Menu("Mode") {
            Button("All") {
                store.selectedMode = nil
                Task { await store.applyFilters() }
            }

            ForEach([TimerMode.focus, TimerMode.relax], id: \.self) { mode in
                Button(mode.title) {
                    store.selectedMode = mode
                    Task { await store.applyFilters() }
                }
            }
        }
    }

    private var statusFilterMenu: some View {
        Menu("Status") {
            Button("All") {
                store.selectedStatus = nil
                Task { await store.applyFilters() }
            }

            ForEach(
                [
                    FocusSessionStatus.completed,
                    FocusSessionStatus.cancelled,
                    FocusSessionStatus.active,
                    FocusSessionStatus.paused
                ],
                id: \.self
            ) { status in
                Button(status.title) {
                    store.selectedStatus = status
                    Task { await store.applyFilters() }
                }
            }
        }
    }
}

private struct SessionRowView: View {
    let session: FocusSession

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.title ?? session.mode.title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                Text(session.status.title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(statusColor)
            }

            HStack(spacing: 12) {
                Label(session.mode.title, systemImage: "timer")

                Text(formattedDate)

                Spacer()

                if let integrity = session.focusIntegrity {
                    Text("\(Int(integrity.rounded()))%")
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }

    private var formattedDate: String {
        session.startedAt.formatted(
            date: .abbreviated,
            time: .shortened
        )
    }

    private var statusColor: Color {
        switch session.status {
        case .active:
            .green
        case .paused:
            .orange
        case .completed:
            .blue
        case .cancelled:
            .secondary
        }
    }
}

private struct SessionDetailView: View {
    let session: FocusSession

    var body: some View {
        NavigationStack {
            List {
                Section("Session") {
                    detail("Mode", session.mode.title)
                    detail("Status", session.status.title)
                    detail(
                        "Started",
                        session.startedAt.formatted(
                            date: .abbreviated,
                            time: .shortened
                        )
                    )

                    if let endedAt = session.endedAt {
                        detail(
                            "Ended",
                            endedAt.formatted(
                                date: .abbreviated,
                                time: .shortened
                            )
                        )
                    }
                }

                Section("Focus") {
                    detail(
                        "Planned",
                        duration(session.plannedDurationSeconds)
                    )
                    detail(
                        "Focused",
                        duration(session.focusedDurationSeconds)
                    )
                    detail(
                        "Interrupted",
                        duration(session.interruptedDurationSeconds)
                    )
                    detail(
                        "Interruptions",
                        String(session.interruptionCount)
                    )

                    if let integrity = session.focusIntegrity {
                        detail(
                            "Focus Integrity",
                            "\(Int(integrity.rounded()))%"
                        )
                    }
                }
            }
            .navigationTitle("Session")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func detail(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }

    private func duration(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60

        if minutes > 0 {
            return String(format: "%dm %02ds", minutes, remainingSeconds)
        }

        return "\(remainingSeconds)s"
    }
}

private extension TimerMode {
    var title: String {
        switch self {
        case .focus:
            "Focus"
        case .relax:
            "Relax"
        }
    }
}

private extension FocusSessionStatus {
    var title: String {
        switch self {
        case .active:
            "Active"
        case .paused:
            "Paused"
        case .completed:
            "Completed"
        case .cancelled:
            "Cancelled"
        }
    }
}

private extension APIError {
    var userMessage: String {
        switch self {
        case .invalidURL:
            "The sessions request URL is invalid."
        case .invalidResponse:
            "The server returned an invalid response."
        case .unauthorized:
            "Your session has expired. Please sign in again."
        case .forbidden:
            "You do not have permission to view these sessions."
        case .notFound:
            "The sessions endpoint could not be found."
        case .conflict:
            "The request could not be completed because of a conflict."
        case .validation(let message):
            message
        case .server(let statusCode):
            "The server returned an error (HTTP \(statusCode))."
        case .network(let message):
            message
        case .decoding(let message):
            message
        case .unknown(let message):
            message
        }
    }
}
