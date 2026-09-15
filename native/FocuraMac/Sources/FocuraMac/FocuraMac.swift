import AppKit
import Foundation
import Network
import SwiftUI

struct MacBridgeState: Codable, Sendable {
    let mode: String
    let status: String
    let duration: Int
    let remaining: Int
    let startedAt: String?
    let endAt: Double?
    let sessionId: Int?
    let title: String?
}

@MainActor
final class MacBridgeStore: ObservableObject {
    @Published private(set) var state =
        MacBridgeState(
            mode: "focus",
            status: "idle",
            duration: 25 * 60,
            remaining: 25 * 60,
            startedAt: nil,
            endAt: nil,
            sessionId: nil,
            title: nil
        )

    func update(
        with newState: MacBridgeState
    ) {
        state = newState
    }
}

final class LocalBridgeServer: @unchecked Sendable {
    private let port: UInt16 = 43127
    private let store: MacBridgeStore

    private var listener: NWListener?

    init(store: MacBridgeStore) {
        self.store = store
    }

    func start() {
        guard listener == nil else {
            return
        }

        do {
            let parameters = NWParameters.tcp

            parameters.requiredLocalEndpoint =
                NWEndpoint.hostPort(
                    host: NWEndpoint.Host(
                        "127.0.0.1"
                    ),
                    port: NWEndpoint.Port(
                        rawValue: port
                    )!
                )

            let listener =
                try NWListener(
                    using: parameters
                )

            self.listener = listener

            let port = self.port

            listener.stateUpdateHandler = {
                state in
                switch state {
                case .ready:
                    print(
                        "Focura bridge listening on 127.0.0.1:\(port)"
                    )

                case .failed(let error):
                    print(
                        "Focura bridge failed: \(error)"
                    )

                case .cancelled:
                    print(
                        "Focura bridge stopped."
                    )

                default:
                    break
                }
            }

            listener.newConnectionHandler = {
                [weak self] connection in

                self?.handle(
                    connection
                )
            }

            listener.start(
                queue: DispatchQueue(
                    label:
                        "com.focura.mac-bridge"
                )
            )
        } catch {
            print(
                "Unable to start Focura bridge: \(error)"
            )
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }

    private func handle(
        _ connection: NWConnection
    ) {
        connection.stateUpdateHandler = {
            state in

            if case .failed = state {
                connection.cancel()
            }
        }

        connection.start(
            queue: DispatchQueue(
                label:
                    "com.focura.mac-bridge.connection"
            )
        )

        receive(
            from: connection,
            accumulatedData: Data()
        )
    }

    private func receive(
        from connection: NWConnection,
        accumulatedData: Data
    ) {
        connection.receive(
            minimumIncompleteLength: 1,
            maximumLength: 65_536
        ) {
            [weak self]
            data,
            _,
            isComplete,
            error in

            guard let self else {
                connection.cancel()
                return
            }

            var buffer = accumulatedData

            if let data {
                buffer.append(data)
            }

            guard let headerRange =
                buffer.range(
                    of: Data(
                        "\r\n\r\n".utf8
                    )
                )
            else {
                if isComplete || error != nil {
                    connection.cancel()
                    return
                }

                self.receive(
                    from: connection,
                    accumulatedData: buffer
                )

                return
            }

            let headerData =
                buffer.subdata(
                    in:
                        0..<headerRange.lowerBound
                )

            let bodyStart =
                headerRange.upperBound

            let bodyData =
                buffer.subdata(
                    in:
                        bodyStart..<buffer.count
                )

            let headers =
                String(
                    data: headerData,
                    encoding: .utf8
                ) ?? ""

            let contentLength =
                self.contentLength(
                    from: headers
                )

            if bodyData.count < contentLength {
                self.receive(
                    from: connection,
                    accumulatedData: buffer
                )

                return
            }

            let requestBody =
                Data(
                    bodyData.prefix(
                        contentLength
                    )
                )

            self.handleRequest(
                headers: headers,
                body: requestBody,
                connection: connection
            )
        }
    }

    private func contentLength(
        from headers: String
    ) -> Int {
        for line in headers.split(
            separator: "\r\n"
        ) {
            let lowercased =
                line.lowercased()

            guard lowercased.hasPrefix(
                "content-length:"
            ) else {
                continue
            }

            let value =
                line.split(
                    separator: ":",
                    maxSplits: 1
                )
                .last?
                .trimmingCharacters(
                    in: .whitespaces
                )

            return Int(
                value ?? ""
            ) ?? 0
        }

        return 0
    }

    private func handleRequest(
        headers: String,
        body: Data,
        connection: NWConnection
    ) {
        let requestLine =
            headers
                .split(
                    separator: "\r\n"
                )
                .first
                .map(String.init) ?? ""

        let parts =
            requestLine.split(
                separator: " ",
                omittingEmptySubsequences: true
            )

        let method =
            parts.first
                .map(String.init) ?? ""

        let path =
            parts.dropFirst()
                .first
                .map(String.init) ?? ""

        if method == "OPTIONS" {
            respond(
                status: "204 No Content",
                body: Data(),
                connection: connection
            )

            return
        }

        if method == "GET" &&
            path == "/health" {
            let response =
                #"{"status":"ok","service":"FocuraMac"}"#

            respond(
                status: "200 OK",
                body: Data(
                    response.utf8
                ),
                connection: connection
            )

            return
        }

        if method == "POST" &&
            path == "/state" {
            handleState(
                body: body,
                connection: connection
            )

            return
        }

        respond(
            status: "404 Not Found",
            body: Data(
                #"{"error":"Not found"}"#.utf8
            ),
            connection: connection
        )
    }

    private func handleState(
        body: Data,
        connection: NWConnection
    ) {
        do {
            let state =
                try JSONDecoder().decode(
                    MacBridgeState.self,
                    from: body
                )

            Task { @MainActor [store] in
                store.update(
                    with: state
                )
            }

            respond(
                status: "200 OK",
                body: Data(
                    #"{"ok":true}"#.utf8
                ),
                connection: connection
            )
        } catch {
            respond(
                status: "400 Bad Request",
                body: Data(
                    #"{"error":"Invalid state"}"#.utf8
                ),
                connection: connection
            )
        }
    }

    private func respond(
        status: String,
        body: Data,
        connection: NWConnection
    ) {
        let header =
            "HTTP/1.1 \(status)\r\n" +
            "Content-Type: application/json; charset=utf-8\r\n" +
            "Content-Length: \(body.count)\r\n" +
            "Access-Control-Allow-Origin: *\r\n" +
            "Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n" +
            "Access-Control-Allow-Headers: Content-Type\r\n" +
            "Cache-Control: no-store\r\n" +
            "Connection: close\r\n" +
            "\r\n"

        var response =
            Data(header.utf8)

        response.append(body)

        connection.send(
            content: response,
            contentContext: .finalMessage,
            isComplete: true,
            completion: .contentProcessed { error in
                if let error {
                    print(
                        "Focura bridge response error: \(error)"
                    )
                }
            }
        )
    }
}

@main
struct FocuraMacApp: App {
    @StateObject private var bridgeStore:
        MacBridgeStore

    private let bridgeServer:
        LocalBridgeServer

    init() {
        let store =
            MacBridgeStore()

        _bridgeStore =
            StateObject(
                wrappedValue: store
            )

        bridgeServer =
            LocalBridgeServer(
                store: store
            )

        bridgeServer.start()

        NSApplication.shared.setActivationPolicy(
            .accessory
        )
    }

    var body: some Scene {
        MenuBarExtra {
            FocuraMenuView(
                state: bridgeStore.state
            )
        } label: {
            FocuraMenuBarIcon()
        }
        .menuBarExtraStyle(.window)
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

@ViewBuilder
private func focuraLiquidGlass<Content: View>(
    @ViewBuilder content: () -> Content
) -> some View {
    if #available(macOS 26.0, *) {
        content()
            .glassEffect(
                .regular,
                in: .rect(
                    cornerRadius: 18
                )
            )
    } else {
        content()
    }
}

struct FocuraLiquidGlass: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content
                .glassEffect(
                    .regular,
                    in: .rect(
                        cornerRadius: 18
                    )
                )
        } else {
            content
        }
    }
}

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

struct FocuraMenuView: View {
    let state: MacBridgeState

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
            spacing: 10
        ) {
            if let image = loadLogo() {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(
                        contentMode: .fit
                    )
                    .frame(
                        width: 30,
                        height: 30
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
                    state.mode == "focus"
                        ? "Focus"
                        : "Relax",
                    systemImage:
                        state.mode == "focus"
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

            if state.status == "running" ||
               state.status == "paused" ||
               state.status == "completed" {
                Text(
                    formattedTime(
                        state.remaining
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

                if state.status == "running" {
                    Text(
                        state.mode == "focus"
                            ? "Stay with your work."
                            : "Take your time."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                } else if state.status == "paused" {
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
        case "running":
            return state.mode == "focus"
                ? "Focusing"
                : "Relaxing"

        case "paused":
            return "Paused"

        case "completed":
            return "Completed"

        case "idle":
            return "Ready"

        default:
            return "Ready"
        }
    }

    private var statusColor: Color {
        switch state.status {
        case "running":
            return .green

        case "paused":
            return .orange

        case "completed":
            return .blue

        default:
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
        guard let url =
            Bundle.module.url(
                forResource: "focura-icon",
                withExtension: "svg"
            )
        else {
            return nil
        }

        return NSImage(
            contentsOf: url
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

