import SwiftUI
import WidgetKit

struct FocuraWidgetEntry: TimelineEntry {
    let date: Date
    let state: FocuraWidgetState
}

struct FocuraWidgetProvider: TimelineProvider {
    func placeholder(
        in context: Context
    ) -> FocuraWidgetEntry {
        FocuraWidgetEntry(
            date: Date(),
            state: FocuraWidgetState(
                mode: .focus,
                status: .running,
                duration: 25 * 60,
                remaining: 24 * 60 + 37,
                startedAt: nil,
                endAt: Date().addingTimeInterval(24 * 60 + 37).timeIntervalSince1970 * 1000.0,
                sessionId: nil,
                title: "Deep work"
            )
        )
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (FocuraWidgetEntry) -> Void
    ) {
        let state = FocuraWidgetStorage.load()
            ?? FocuraWidgetState(
                mode: .focus,
                status: .idle,
                duration: 25 * 60,
                remaining: 25 * 60,
                startedAt: nil,
                endAt: nil,
                sessionId: nil,
                title: nil
            )

        completion(
            FocuraWidgetEntry(
                date: Date(),
                state: state
            )
        )
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (
            Timeline<FocuraWidgetEntry>
        ) -> Void
    ) {
        let state = FocuraWidgetStorage.load()
            ?? FocuraWidgetState(
                mode: .focus,
                status: .idle,
                duration: 25 * 60,
                remaining: 25 * 60,
                startedAt: nil,
                endAt: nil,
                sessionId: nil,
                title: nil
            )

        let entry = FocuraWidgetEntry(
            date: Date(),
            state: state
        )

        let policyDate: Date

        if state.status == .running,
           let endAt = state.endAt {
            policyDate = Date(
                timeIntervalSince1970: endAt / 1000.0
            )
        } else {
            policyDate = Date().addingTimeInterval(15 * 60)
        }

        completion(
            Timeline(
                entries: [entry],
                policy: .after(policyDate)
            )
        )
    }
}

struct FocuraWidgetEntryView: View {
    let entry: FocuraWidgetEntry

    private var state: FocuraWidgetState {
        entry.state
    }

    private var isRunning: Bool {
        state.status == .running
    }

    private var statusTitle: String {
        switch state.status {
        case .running:
            return state.mode == .focus
                ? "Focus"
                : "Relax"

        case .paused:
            return "Paused"

        case .completed:
            return "Completed"

        case .idle:
            return "Ready"
        }
    }

    private var caption: String {
        switch state.status {
        case .running:
            return state.mode == .focus
                ? "Stay with your work."
                : "Take your time."

        case .paused:
            return "Timer is paused."

        case .completed:
            return "Session completed."

        case .idle:
            return "Open Focura to start a session."
        }
    }

    private var statusSymbol: String {
        switch state.status {
        case .running:
            return state.mode == .focus
                ? "circle.fill"
                : "leaf.fill"

        case .paused:
            return "pause.fill"

        case .completed:
            return "checkmark.circle.fill"

        case .idle:
            return "circle.dashed"
        }
    }

    private var statusTint: Color {
        switch state.status {
        case .running:
            return state.mode == .focus
                ? .blue
                : .green

        case .paused:
            return .orange

        case .completed:
            return .blue

        case .idle:
            return .secondary
        }
    }

    private var formattedRemaining: String {
        let total = max(
            0,
            Int(state.remaining)
        )

        let minutes = total / 60
        let seconds = total % 60

        return String(
            format: "%02d:%02d",
            minutes,
            seconds
        )
    }

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 0
        ) {
            HStack(
                alignment: .center,
                spacing: 8
            ) {
                Image("focura-icon")
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: 24,
                        height: 24
                    )

                Text("Focura")
                    .font(
                        .system(
                            size: 14,
                            weight: .semibold
                        )
                    )

                Spacer()

                Label(
                    statusTitle,
                    systemImage: statusSymbol
                )
                .font(
                    .system(
                        size: 11,
                        weight: .medium
                    )
                )
                .foregroundStyle(statusTint)
            }

            Spacer(minLength: 12)

            if isRunning,
               let endAt = state.endAt {
                Text(
                    Date(
                        timeIntervalSince1970: endAt / 1000.0
                    ),
                    style: .timer
                )
                .font(
                    .system(
                        size: 34,
                        weight: .semibold,
                        design: .rounded
                    )
                )
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            } else {
                Text(formattedRemaining)
                    .font(
                        .system(
                            size: 34,
                            weight: .semibold,
                            design: .rounded
                        )
                    )
                    .monospacedDigit()
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if let title = state.title,
               !title.trimmingCharacters(
                    in: .whitespacesAndNewlines
               ).isEmpty {
                Text(title)
                    .font(
                        .system(
                            size: 12,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }

            Text(caption)
                .font(
                    .system(
                        size: 11,
                        weight: .regular
                    )
                )
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )
        }
        .containerBackground(
            .fill.tertiary,
            for: .widget
        )
    }
}

struct FocuraWidget: Widget {
    let kind: String = "FocuraWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: FocuraWidgetProvider()
        ) { entry in
            FocuraWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Focura")
        .description(
            "See your current focus or relax session at a glance."
        )
        .supportedFamilies([
            .systemSmall,
            .systemMedium
        ])
    }
}
