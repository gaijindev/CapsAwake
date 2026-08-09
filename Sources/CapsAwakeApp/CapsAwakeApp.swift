import AppKit
import SwiftUI

@main
struct CapsAwakeApp: App {
    @StateObject private var model = AppModel()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(model: model)
        } label: {
            Image(systemName: model.menuBarSymbol)
                .symbolRenderingMode(.monochrome)
                .accessibilityLabel(model.statusTitle)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(model: model)
        }
    }
}
