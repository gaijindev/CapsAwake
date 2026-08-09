import AppKit
import CapsAwakeCore
import Foundation

@MainActor
final class CapsLockMonitor {
    private var timer: Timer?
    private(set) var isOn = false
    var onChange: (() -> Void)?

    init() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in Task { @MainActor in self?.refresh() } }
        NotificationCenter.default.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in Task { @MainActor in self?.refresh() } }
    }

    func refresh() {
        let next = NSEvent.modifierFlags.contains(.capsLock)
        guard next != isOn else { return }
        isOn = next
        onChange?()
    }
}
