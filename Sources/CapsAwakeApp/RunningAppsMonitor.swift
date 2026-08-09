import AppKit
import CapsAwakeCore
import Foundation

@MainActor
final class RunningAppsMonitor {
    private(set) var runningBundleIdentifiers: Set<String> = []
    private(set) var frontmostBundleIdentifier: String?
    var onChange: (() -> Void)?

    init() {
        refresh()
        let workspace = NSWorkspace.shared
        let center = workspace.notificationCenter
        for name in [
            NSWorkspace.didLaunchApplicationNotification,
            NSWorkspace.didTerminateApplicationNotification,
            NSWorkspace.didActivateApplicationNotification,
        ] {
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.refresh() }
            }
        }
    }

    deinit {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    func refresh() {
        runningBundleIdentifiers = Set(
            NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier)
        )
        frontmostBundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        onChange?()
    }

    func isAppAvailable(_ rule: AppRule) -> Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: rule.bundleIdentifier) != nil
    }
}
