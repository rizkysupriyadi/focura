import SwiftUI
import AppKit

@main
struct FocuraMacXcodeApp: App {
    @StateObject private var bridgeStore: MacBridgeStore
    private let bridgeServer: LocalBridgeServer

    init() {
        print("FocuraMacApp: init started")
        let store = MacBridgeStore()

        _bridgeStore = StateObject(
            wrappedValue: store
        )

        bridgeServer = LocalBridgeServer(
            store: store
        )

        print("FocuraMacApp: starting bridge server")
        bridgeServer.start()
        print("FocuraMacApp: bridge server start requested")

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
