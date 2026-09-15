import AppKit
import SwiftUI

enum FocuraAppearance: String, CaseIterable {
    case light
    case dark
    case liquid

    var title: String {
        switch self {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case .liquid:
            return "Liquid"
        }
    }

    var icon: String {
        switch self {
        case .light:
            return "sun.max"
        case .dark:
            return "moon"
        case .liquid:
            return "circle.lefthalf.filled"
        }
    }
}

struct FocuraMenuBarIcon: View {
    var body: some View {
        Text("F")
            .font(
                .system(
                    size: 11,
                    weight: .bold,
                    design: .rounded
                )
            )
            .foregroundStyle(.white)
    }
}

struct FocuraMenuView: View {
    let state: FocuraWidgetState

    @AppStorage("focura.appearance")
    private var appearance =
        FocuraAppearance.liquid.rawValue

    private var selectedAppearance:
        FocuraAppearance {
        FocuraAppearance(
            rawValue: appearance
        ) ?? .liquid
    }

    var body: some View {
        content
            .environment(
                \.colorScheme,
                selectedColorScheme
            )
            .background {
                appearanceBackground
            }
            .onAppear {
                applyNativeAppearance()
            }
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UserDefaults.didChangeNotification
                )
            ) { _ in
                applyNativeAppearance()
            }
    }

    private var content: some View {
        VStack(
            alignment: .leading,
            spacing: 0
        ) {
            header

            Divider()
                .padding(.vertical, 14)

            statusSection

            Divider()
                .padding(.vertical, 14)

            appearanceSection

            Divider()
                .padding(.vertical, 14)

            actions
        }
        .padding(16)
        .frame(width: 300)
    }

    private var header: some View {
        HStack(
            alignment: .center,
            spacing: 8
        ) {
            if let image = loadLogo() {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(
                        contentMode: .fit
                    )
                    .frame(
                        width: 22,
                        height: 22
                    )
            }

            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                Text("Focura")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("Focus with intention.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
    }

    private var statusSection: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            HStack {
                Label(
                    state.mode == .focus
                        ? "Focus"
                        : "Relax",
                    systemImage:
                        state.mode == .focus
                            ? "scope"
                            : "wind"
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Spacer()

                statusBadge
            }

            if let title = state.title,
               !title.isEmpty {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }

            if state.status == .running ||
               state.status == .paused ||
               state.status == .completed {
                countdownText

                if state.status == .running {
                    Text(
                        state.mode == .focus
                            ? "Stay with your work."
                            : "Take your time."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                } else if state.status == .paused {
                    Text("Timer is paused.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Session completed.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(
                    alignment: .leading,
                    spacing: 5
                ) {
                    Text("Ready")
                        .font(.title3)
                        .fontWeight(.medium)

                    Text(
                        "Open Focura to start or manage a session."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
                }
            }
        }
    }

    private var countdownText: some View {
        TimelineView(
            .periodic(
                from: .now,
                by: 1
            )
        ) { context in
            Text(
                formattedCountdown(
                    at: context.date
                )
            )
            .font(
                .system(
                    size: 36,
                    weight: .medium,
                    design: .rounded
                )
            )
            .monospacedDigit()
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
    }

    private func formattedCountdown(
        at date: Date
    ) -> String {
        let remaining: Int

        if state.status == .running,
           let endAt = state.endAt {
            remaining = max(
                0,
                Int(
                    ceil(
                        endAt.timeIntervalSince(
                            date
                        )
                    )
                )
            )
        } else {
            remaining = max(
                0,
                Int(ceil(state.remaining))
            )
        }

        return formattedTime(remaining)
    }

    private var statusBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(
                    width: 7,
                    height: 7
                )

            Text(statusText)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(
                    statusColor.opacity(0.12)
                )
        )
    }

    private var appearanceSection: some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            Text("Appearance")
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker(
                "Appearance",
                selection: $appearance
            ) {
                ForEach(
                    FocuraAppearance.allCases,
                    id: \.rawValue
                ) { item in
                    Label(
                        item.title,
                        systemImage: item.icon
                    )
                    .tag(item.rawValue)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
        }
    }

    private var appearanceBackground: some View {
        Group {
            switch selectedAppearance {
            case .light:
                Color.white

            case .dark:
                Color.black

            case .liquid:
                if #available(macOS 26.0, *) {
                    Color.clear
                        .glassEffect(
                            .regular,
                            in: .rect(
                                cornerRadius: 18
                            )
                        )
                } else {
                    Color(nsColor: .windowBackgroundColor)
                }
            }
        }
        .ignoresSafeArea()
    }

    private var selectedColorScheme:
        ColorScheme {
        switch selectedAppearance {
        case .light:
            return .light

        case .dark:
            return .dark

        case .liquid:
            return NSApp.effectiveAppearance
                .bestMatch(
                    from: [
                        .aqua,
                        .darkAqua
                    ]
                ) == .darkAqua
                ? .dark
                : .light
        }
    }

    private func applyNativeAppearance() {
        switch selectedAppearance {
        case .light:
            NSApp.appearance = NSAppearance(
                named: .aqua
            )

        case .dark:
            NSApp.appearance = NSAppearance(
                named: .darkAqua
            )

        case .liquid:
            NSApp.appearance = nil
        }
    }

    private var statusText: String {
        switch state.status {
        case .running:
            return state.mode == .focus
                ? "Focusing"
                : "Relaxing"

        case .paused:
            return "Paused"

        case .completed:
            return "Completed"

        case .idle:
            return "Ready"
        }
    }

    private var statusColor: Color {
        switch state.status {
        case .running:
            return .green

        case .paused:
            return .orange

        case .completed:
            return .blue

        case .idle:
            return .secondary
        }
    }

    private var actions: some View {
        VStack(spacing: 6) {
            Button {
                openFocura()
            } label: {
                Label(
                    "Open Focura",
                    systemImage:
                        "arrow.up.right.square"
                )
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
            }
            .buttonStyle(.borderless)

            Button {
                NSApplication.shared
                    .terminate(nil)
            } label: {
                Label(
                    "Quit Focura",
                    systemImage: "power"
                )
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
            }
            .buttonStyle(.borderless)
        }
    }

    private func formattedTime(
        _ seconds: Int
    ) -> String {
        let safeSeconds = max(0, seconds)

        let minutes = safeSeconds / 60
        let remaining = safeSeconds % 60

        return String(
            format: "%02d:%02d",
            minutes,
            remaining
        )
    }

    private func loadLogo() -> NSImage? {
        NSImage(
            named: "focura-icon"
        )
    }

    private func openFocura() {
        guard let url =
            URL(
                string:
                    "http://localhost:8000/focus"
            )
        else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}
