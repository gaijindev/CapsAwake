import AppKit
import CapsAwakeCore
import Combine
import Foundation

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var plan = AwakePlan.inactive
    @Published private(set) var configuration: AwakeConfiguration
    @Published private(set) var manualSessions: [ManualSession] = []
    @Published private(set) var timerSessions: [TimerSession] = []
    @Published private(set) var warning: String?
    @Published private(set) var capsLockOn = false
    @Published private(set) var automationPaused = false

    let coordinator = AwakeCoordinator()
    let loginItemController = LoginItemController()
    private let powerController = PowerAssertionController()
    private let notificationController = NotificationController()
    private let capsLockMonitor: CapsLockMonitor
    private let runningAppsMonitor: RunningAppsMonitor
    private let store: ConfigurationStore?
    private var coordinatorState = CoordinatorState()
    private var refreshTimer: Timer?
    private var lastPowerError: String?

    init() {
        store = try? ConfigurationStore.appSupportStore()
        let loadedConfiguration = (try? store?.load()) ?? AwakeConfiguration()
        configuration = loadedConfiguration
        timerSessions = loadedConfiguration.timerSessions
        capsLockMonitor = CapsLockMonitor()
        runningAppsMonitor = RunningAppsMonitor()
        capsLockOn = capsLockMonitor.isOn
        capsLockMonitor.onChange = { [weak self] in self?.refresh() }
        runningAppsMonitor.onChange = { [weak self] in self?.refresh() }
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.powerController.releaseAll() }
        }
        refresh()
    }

    var menuBarSymbol: String {
        if !plan.activeReasons.isEmpty { return plan.preventDisplaySleep ? "sun.max.fill" : "capslock.fill" }
        return automationPaused ? "pause.circle" : "capslock"
    }

    var statusTitle: String {
        if automationPaused { return "Automation paused" }
        if plan.preventDisplaySleep { return "Mac and display awake" }
        if plan.preventSystemSleep { return "Mac awake" }
        return "Normal sleep behavior"
    }

    var isOnboardingPresented: Bool {
        !configuration.onboardingCompleted
    }

    func refresh() {
        capsLockOn = capsLockMonitor.isOn
        let missingApps = Set(
            configuration.appRules.compactMap { rule in
                isAppAvailable(rule) ? nil : rule.bundleIdentifier
            })
        let facts = TriggerFacts(
            capsLockOn: capsLockOn,
            now: Date(),
            runningBundleIdentifiers: runningAppsMonitor.runningBundleIdentifiers,
            frontmostBundleIdentifier: runningAppsMonitor.frontmostBundleIdentifier,
            missingBundleIdentifiers: missingApps,
            manualSessions: manualSessions,
            timerSessions: timerSessions,
            configuration: configuration,
            suppressedTriggerIDs: []
        )
        let normalized = coordinator.normalize(facts)
        let expiredTimers = facts.timerSessions.filter { timer in
            guard let expiresAt = timer.expiresAt else { return false }
            return expiresAt <= facts.now
        }
        if configuration.timerEndNotifications {
            for timer in expiredTimers where timer.notifyWhenFinished {
                notificationController.send(title: "Timer finished", body: timer.title)
            }
        }
        if normalized.timerSessions != timerSessions || normalized.configuration != configuration {
            timerSessions = normalized.timerSessions
            configuration = normalized.configuration
            saveConfiguration()
        }
        coordinatorState = coordinator.reconcile(coordinatorState, with: normalized)
        if coordinatorState.suppressedTriggerIDs.isEmpty {
            automationPaused = false
        }
        let previousError = lastPowerError
        plan = coordinator.evaluate(normalized, state: coordinatorState)
        powerController.apply(plan)
        lastPowerError = powerController.lastError
        warning = lastPowerError ?? plan.warnings.first
        if let lastPowerError, lastPowerError != previousError, configuration.assertionFailureNotifications {
            notificationController.send(title: "CapsAwake needs attention", body: lastPowerError)
        }
    }

    func start(_ preset: Preset) {
        guard let session = TimerPlanner.session(from: preset, now: Date()) else {
            manualSessions.append(ManualSession(title: preset.name, mode: preset.mode))
            refresh()
            return
        }
        timerSessions.append(session)
        configuration.timerSessions = timerSessions
        saveConfiguration()
        refresh()
    }

    func startCustom(minutes: Int, mode: AwakeMode = .systemOnly) {
        let session = TimerSession(
            title: "Custom · \(minutes) min", mode: mode,
            expiresAt: Date().addingTimeInterval(TimeInterval(minutes * 60)))
        timerSessions.append(session)
        configuration.timerSessions = timerSessions
        saveConfiguration()
        refresh()
    }

    func startUntil(date: Date, mode: AwakeMode = .systemOnly) {
        let session = TimerSession(
            title: "Until \(date.formatted(date: .omitted, time: .shortened))", mode: mode, expiresAt: date)
        timerSessions.append(session)
        configuration.timerSessions = timerSessions
        saveConfiguration()
        refresh()
    }

    func stopAllSessions() {
        manualSessions.removeAll()
        timerSessions.removeAll()
        configuration.timerSessions.removeAll()
        saveConfiguration()
        refresh()
    }

    func allowSleepNow() {
        let result = coordinator.reduce(.allowSleepNow, facts: currentFacts(), state: coordinatorState)
        coordinatorState = result.state
        automationPaused = true
        plan = result.plan
        powerController.apply(plan)
    }

    func resumeAutomation() {
        let result = coordinator.reduce(.resumeAutomation, facts: currentFacts(), state: coordinatorState)
        coordinatorState = result.state
        automationPaused = false
        plan = result.plan
        powerController.apply(plan)
    }

    func completeOnboarding() {
        configuration.onboardingCompleted = true
        saveConfiguration()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try loginItemController.setEnabled(enabled)
            configuration.launchAtLogin = enabled
            saveConfiguration()
        } catch {
            warning = "Launch at Login could not be updated."
        }
    }

    func setTimerEndNotifications(_ enabled: Bool) {
        configuration.timerEndNotifications = enabled
        saveConfiguration()
        if enabled {
            Task { _ = await notificationController.requestPermission() }
        }
    }

    func setAssertionFailureNotifications(_ enabled: Bool) {
        configuration.assertionFailureNotifications = enabled
        saveConfiguration()
        if enabled {
            Task { _ = await notificationController.requestPermission() }
        }
    }

    func updatePreset(_ preset: Preset) {
        guard let index = configuration.presets.firstIndex(where: { $0.id == preset.id }) else { return }
        configuration.presets[index] = preset
        saveConfiguration()
        refresh()
    }

    func addPreset() {
        configuration.presets.append(Preset(name: "New Preset", mode: .systemOnly, duration: .fixed(30 * 60)))
        saveConfiguration()
    }

    func removePreset(_ preset: Preset) {
        configuration.presets.removeAll { $0.id == preset.id }
        saveConfiguration()
    }

    func addSchedule() {
        configuration.schedules.append(
            WeeklySchedule(
                name: "Weekday focus",
                weekdays: [.monday, .tuesday, .wednesday, .thursday, .friday],
                startMinutes: 9 * 60,
                endMinutes: 17 * 60
            )
        )
        saveConfiguration()
        refresh()
    }

    func removeSchedule(_ schedule: WeeklySchedule) {
        configuration.schedules.removeAll { $0.id == schedule.id }
        saveConfiguration()
        refresh()
    }

    func updateSchedule(_ schedule: WeeklySchedule) {
        guard let index = configuration.schedules.firstIndex(where: { $0.id == schedule.id }) else { return }
        configuration.schedules[index] = schedule
        saveConfiguration()
        refresh()
    }

    func toggleWeekday(_ weekday: ScheduleWeekday, for schedule: WeeklySchedule) {
        var updated = schedule
        if updated.weekdays.contains(weekday) {
            updated.weekdays.remove(weekday)
        } else {
            updated.weekdays.insert(weekday)
        }
        updateSchedule(updated)
    }

    func skipNext(_ schedule: WeeklySchedule) {
        guard let index = configuration.schedules.firstIndex(where: { $0.id == schedule.id }) else { return }
        configuration.schedules[index] = coordinator.scheduleSkippingNextOccurrence(
            configuration.schedules[index], now: Date(), calendar: .autoupdatingCurrent)
        saveConfiguration()
        refresh()
    }

    func addAppRule(
        name: String = "New app rule", bundleIdentifier: String = "com.apple.TextEdit",
        match: AppRuleMatch = .whileFrontmost
    ) {
        configuration.appRules.append(
            AppRule(name: name, bundleIdentifier: bundleIdentifier, match: match)
        )
        saveConfiguration()
        refresh()
    }

    func removeAppRule(_ rule: AppRule) {
        configuration.appRules.removeAll { $0.id == rule.id }
        saveConfiguration()
        refresh()
    }

    func updateAppRule(_ rule: AppRule) {
        guard let index = configuration.appRules.firstIndex(where: { $0.id == rule.id }) else { return }
        configuration.appRules[index] = rule
        saveConfiguration()
        refresh()
    }

    func isAppAvailable(_ rule: AppRule) -> Bool {
        runningAppsMonitor.isAppAvailable(rule)
    }

    func quit() {
        manualSessions.removeAll()
        timerSessions.removeAll()
        configuration.timerSessions.removeAll()
        saveConfiguration()
        powerController.releaseAll()
        NSApplication.shared.terminate(nil)
    }

    func retryPowerAssertion() {
        refresh()
    }

    func exportConfiguration() -> Data? {
        try? store?.exportData(configuration)
    }

    func importConfiguration(_ data: Data, mode: ImportMode) {
        do {
            guard let store else { return }
            configuration = try store.importData(data, mode: mode, into: configuration)
            saveConfiguration()
            refresh()
        } catch {
            warning = error.localizedDescription
        }
    }

    func previewAndImport(_ data: Data) {
        do {
            guard let store else { return }
            let preview = try store.previewImport(data)
            let alert = NSAlert()
            alert.messageText = "Import CapsAwake configuration?"
            alert.informativeText =
                "Schema \(preview.schemaVersion) · \(preview.presetCount) presets · \(preview.scheduleCount) schedules · \(preview.appRuleCount) app rules"
            alert.addButton(withTitle: "Merge")
            alert.addButton(withTitle: "Replace")
            alert.addButton(withTitle: "Cancel")
            switch alert.runModal() {
            case .alertFirstButtonReturn:
                importConfiguration(data, mode: .merge)
            case .alertSecondButtonReturn:
                importConfiguration(data, mode: .replace)
            default:
                break
            }
        } catch {
            warning = error.localizedDescription
        }
    }

    private func currentFacts() -> TriggerFacts {
        TriggerFacts(
            capsLockOn: capsLockMonitor.isOn,
            now: Date(),
            runningBundleIdentifiers: runningAppsMonitor.runningBundleIdentifiers,
            frontmostBundleIdentifier: runningAppsMonitor.frontmostBundleIdentifier,
            missingBundleIdentifiers: Set(
                configuration.appRules.compactMap { isAppAvailable($0) ? nil : $0.bundleIdentifier }),
            manualSessions: manualSessions,
            timerSessions: timerSessions,
            configuration: configuration
        )
    }

    private func saveConfiguration() {
        do {
            try store?.save(configuration)
        } catch {
            warning = "CapsAwake could not save settings."
        }
    }
}
