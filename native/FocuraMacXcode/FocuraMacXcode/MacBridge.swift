import Foundation
import Combine
import Network
import WidgetKit

@MainActor
final class MacBridgeStore: ObservableObject {
    @Published private(set) var state = FocuraWidgetState(
        mode: .focus,
        status: .idle,
        duration: 25 * 60,
        remaining: 25 * 60,
        startedAt: nil,
        endAt: nil,
        sessionId: nil,
        title: nil
    )

    func update(with newState: FocuraWidgetState) {
        state = newState

        print(
            "FocuraMac received state: " +
            "mode=\(newState.mode.rawValue), " +
            "status=\(newState.status.rawValue), " +
            "remaining=\(newState.remaining), " +
            "endAt=\(String(describing: newState.endAt))"
        )

        if let fileURL = FocuraWidgetStorage.fileURL {
            print(
                "FocuraMac widget state path: \(fileURL.path)"
            )
        } else {
            print(
                "FocuraMac ERROR: App Group container unavailable"
            )
        }

        FocuraWidgetStorage.save(newState)

        WidgetCenter.shared.reloadTimelines(
            ofKind: "FocuraWidget"
        )
    }
}

final class LocalBridgeServer {
    private let port: NWEndpoint.Port
    private let store: MacBridgeStore
    private var listener: NWListener?

    init(
        store: MacBridgeStore,
        port: UInt16 = 43127
    ) {
        self.store = store
        self.port = NWEndpoint.Port(rawValue: port)!
    }

    func start() {
        guard listener == nil else {
            return
        }

        do {
            let listener = try NWListener(
                using: .tcp,
                on: port
            )

            listener.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print(
                        "FocuraMac bridge listening on 127.0.0.1:43127"
                    )
                case .failed(let error):
                    print(
                        "FocuraMac bridge failed: \(error)"
                    )
                default:
                    break
                }
            }

            listener.newConnectionHandler = { [weak self] connection in
                self?.handle(connection)
            }

            self.listener = listener

            listener.start(
                queue: DispatchQueue(
                    label: "com.focura.mac.bridge"
                )
            )
        } catch {
            print(
                "Unable to start FocuraMac bridge: \(error)"
            )
        }
    }

    private func handle(_ connection: NWConnection) {
        connection.start(
            queue: DispatchQueue(
                label: "com.focura.mac.bridge.connection"
            )
        )

        receive(
            connection,
            data: Data()
        )
    }

    private func receive(
        _ connection: NWConnection,
        data: Data
    ) {
        connection.receive(
            minimumIncompleteLength: 1,
            maximumLength: 64 * 1024
        ) { [weak self] receivedData, _, isComplete, error in
            guard let self else {
                connection.cancel()
                return
            }

            var buffer = data

            if let receivedData {
                buffer.append(receivedData)
            }

            if let request = String(
                data: buffer,
                encoding: .utf8
            ) {
                let separator = "\r\n\r\n"

                if let separatorRange = request.range(
                    of: separator
                ) {
                    let headerPart = String(
                        request[..<separatorRange.lowerBound]
                    )

                    let contentLength = headerPart
                        .components(separatedBy: "\r\n")
                        .compactMap { line -> Int? in
                            let parts = line.split(
                                separator: ":",
                                maxSplits: 1
                            )

                            guard parts.count == 2 else {
                                return nil
                            }

                            guard parts[0]
                                .trimmingCharacters(
                                    in: .whitespaces
                                )
                                .lowercased() == "content-length"
                            else {
                                return nil
                            }

                            return Int(
                                parts[1]
                                    .trimmingCharacters(
                                        in: .whitespaces
                                    )
                            )
                        }
                        .first ?? 0

                    let body = String(
                        request[
                            separatorRange.upperBound...
                        ]
                    )

                    if body.utf8.count >= contentLength {
                        self.process(
                            request,
                            connection: connection
                        )
                        return
                    }
                }
            }

            if isComplete || error != nil {
                connection.cancel()
                return
            }

            self.receive(
                connection,
                data: buffer
            )
        }
    }

    private func process(
        _ request: String,
        connection: NWConnection
    ) {
        let separator = "\r\n\r\n"

        guard let separatorRange = request.range(
            of: separator
        ) else {
            send(
                status: "400 Bad Request",
                body: #"{"error":"invalid_request"}"#,
                connection: connection
            )
            return
        }

        let headerPart = String(
            request[..<separatorRange.lowerBound]
        )

        let body = String(
            request[separatorRange.upperBound...]
        )

        let lines = headerPart.components(
            separatedBy: "\r\n"
        )

        guard let requestLine = lines.first else {
            send(
                status: "400 Bad Request",
                body: #"{"error":"invalid_request"}"#,
                connection: connection
            )
            return
        }

        let components = requestLine.split(
            separator: " ",
            maxSplits: 2
        )

        guard components.count >= 2 else {
            send(
                status: "400 Bad Request",
                body: #"{"error":"invalid_request"}"#,
                connection: connection
            )
            return
        }

        let method = String(components[0])
        let path = String(components[1])

        if method == "OPTIONS" {
            send(
                status: "204 No Content",
                body: "",
                connection: connection
            )
            return
        }

        if method == "GET" && path == "/health" {
            send(
                status: "200 OK",
                body: #"{"status":"ok","service":"FocuraMac"}"#,
                connection: connection
            )
            return
        }

        if method == "POST" && path == "/state" {
            guard let stateData = body.data(
                using: .utf8
            ) else {
                send(
                    status: "400 Bad Request",
                    body: #"{"error":"invalid_body"}"#,
                    connection: connection
                )
                return
            }

            do {
                let state = try JSONDecoder().decode(
                    FocuraWidgetState.self,
                    from: stateData
                )

                Task { @MainActor [store] in
                    store.update(with: state)
                }

                send(
                    status: "200 OK",
                    body: #"{"ok":true}"#,
                    connection: connection
                )
            } catch {
                print(
                    "FocuraMac bridge decode error: \(error)"
                )

                send(
                    status: "400 Bad Request",
                    body: #"{"error":"invalid_state"}"#,
                    connection: connection
                )
            }

            return
        }

        send(
            status: "404 Not Found",
            body: #"{"error":"not_found"}"#,
            connection: connection
        )
    }

    private func send(
        status: String,
        body: String,
        connection: NWConnection
    ) {
        let bodyData = Data(body.utf8)

        let response =
            "HTTP/1.1 \(status)\r\n" +
            "Content-Type: application/json; charset=utf-8\r\n" +
            "Content-Length: \(bodyData.count)\r\n" +
            "Access-Control-Allow-Origin: http://127.0.0.1:8000\r\n" +
            "Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n" +
            "Access-Control-Allow-Headers: Content-Type\r\n" +
            "Cache-Control: no-store\r\n" +
            "Connection: close\r\n" +
            "\r\n" +
            body

        connection.send(
            content: Data(response.utf8),
            completion: .contentProcessed { _ in
                connection.cancel()
            }
        )
    }
}
