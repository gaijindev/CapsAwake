import Foundation
import Testing

@testable import CapsAwakeCore

struct AwakeCoordinatorTests {
    private let coordinator = AwakeCoordinator()
    private let now = Date(timeIntervalSince1970: 1_735_689_600)

    @Test("Caps Lock creates a system sleep plan")
    func capsLockCreatesPlan() {
        let plan = coordinator.evaluate(TriggerFacts(capsLockOn: true, now: now))
        #expect(plan.preventSystemSleep)
        #expect(!plan.preventDisplaySleep)
        #expect(plan.activeReasons.map(\.title) == ["Caps Lock is on"])
    }

    @Test("display awake wins when any trigger requests it")
    func displayPolicyPrecedence() {
        let timer = TimerSession(title: "Presentation", mode: .systemAndDisplay, expiresAt: now.addingTimeInterval(900))
        let plan = coordinator.evaluate(TriggerFacts(capsLockOn: true, now: now, timerSessions: [timer]))
        #expect(plan.preventSystemSleep)
        #expect(plan.preventDisplaySleep)
        #expect(plan.activeReasons.count == 2)
    }

    @Test("expired timers do not keep the Mac awake")
    func expiredTimerIsInactive() {
        let timer = TimerSession(title: "Finished", mode: .systemOnly, expiresAt: now.addingTimeInterval(-1))
        let plan = coordinator.evaluate(TriggerFacts(capsLockOn: false, now: now, timerSessions: [timer]))
        #expect(plan == .inactive)
    }

    @Test("Allow Sleep Now suppresses currently active trigger IDs")
    func allowSleepNowSuppressesActiveTriggers() {
        let facts = TriggerFacts(capsLockOn: true, now: now)
        let result = coordinator.reduce(.allowSleepNow, facts: facts)
        #expect(result.plan == .inactive)
        #expect(result.state.suppressedTriggerIDs == ["caps-lock"])

        let resumed = coordinator.reduce(.resumeAutomation, facts: facts, state: result.state)
        #expect(resumed.plan.preventSystemSleep)
    }

    @Test("fact-level suppression is respected")
    func factSuppression() {
        let facts = TriggerFacts(capsLockOn: true, now: now, suppressedTriggerIDs: ["caps-lock"])
        #expect(coordinator.evaluate(facts) == .inactive)
    }

    @Test("reconcile removes suppression after a trigger resets")
    func suppressionReconciliation() {
        let suppressed = CoordinatorState(suppressedTriggerIDs: ["caps-lock"])
        let facts = TriggerFacts(capsLockOn: false, now: now)
        #expect(coordinator.reconcile(suppressed, with: facts).suppressedTriggerIDs.isEmpty)
    }

    @Test("suppression is released after an expired timer resets")
    func timerSuppressionReconciliation() {
        let timer = TimerSession(title: "Bounded", mode: .systemOnly, expiresAt: now.addingTimeInterval(60))
        let activeFacts = TriggerFacts(capsLockOn: false, now: now, timerSessions: [timer])
        let result = coordinator.reduce(.allowSleepNow, facts: activeFacts)
        #expect(result.state.suppressedTriggerIDs.count == 1)

        let expiredFacts = TriggerFacts(capsLockOn: false, now: now.addingTimeInterval(61), timerSessions: [timer])
        let reconciled = coordinator.reconcile(result.state, with: expiredFacts)
        #expect(reconciled.suppressedTriggerIDs.isEmpty)
        #expect(coordinator.evaluate(expiredFacts, state: reconciled) == .inactive)
    }

    @Test("reset suppression command releases one trigger")
    func resetSuppressionCommand() {
        let facts = TriggerFacts(capsLockOn: true, now: now)
        let state = CoordinatorState(suppressedTriggerIDs: ["caps-lock", "timer-other"])
        let result = coordinator.reduce(.resetSuppression(forTriggerID: "caps-lock"), facts: facts, state: state)
        #expect(result.state.suppressedTriggerIDs == ["timer-other"])
        #expect(result.plan.preventSystemSleep)
    }

    @Test("manual sessions activate until their deadline")
    func manualSessionActivation() {
        let session = ManualSession(title: "Manual", mode: .systemOnly, expiresAt: now.addingTimeInterval(60))
        #expect(
            coordinator.evaluate(TriggerFacts(capsLockOn: false, now: now, manualSessions: [session]))
                .preventSystemSleep)
        #expect(
            coordinator.evaluate(
                TriggerFacts(capsLockOn: false, now: now.addingTimeInterval(61), manualSessions: [session]))
                == .inactive)
    }

    @Test("weekly schedules support overnight windows")
    func overnightSchedule() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let schedule = WeeklySchedule(name: "Night", weekdays: [.monday], startMinutes: 23 * 60, endMinutes: 60)
        let mondayLate = calendar.date(from: DateComponents(year: 2026, month: 8, day: 3, hour: 23, minute: 30))!
        let tuesdayEarly = calendar.date(from: DateComponents(year: 2026, month: 8, day: 4, hour: 0, minute: 30))!
        #expect(schedule.isActive(at: mondayLate, calendar: calendar))
        #expect(schedule.isActive(at: tuesdayEarly, calendar: calendar))
    }

    @Test("schedule boundaries are start-inclusive and end-exclusive")
    func scheduleBoundaries() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let schedule = WeeklySchedule(name: "Focus", weekdays: [.monday], startMinutes: 9 * 60, endMinutes: 10 * 60)
        let start = calendar.date(from: DateComponents(year: 2026, month: 8, day: 3, hour: 9))!
        let end = calendar.date(from: DateComponents(year: 2026, month: 8, day: 3, hour: 10))!
        #expect(schedule.isActive(at: start, calendar: calendar))
        #expect(!schedule.isActive(at: end, calendar: calendar))
    }

    @Test("skip next marks only the selected schedule occurrence")
    func skipNextScheduleOccurrence() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let mondayMorning = calendar.date(from: DateComponents(year: 2026, month: 8, day: 3, hour: 9))!
        let schedule = WeeklySchedule(
            name: "Focus",
            weekdays: [.monday],
            startMinutes: 9 * 60,
            endMinutes: 10 * 60,
            skipNextOccurrence: true,
            skippedOccurrenceStart: mondayMorning
        )
        let facts = TriggerFacts(
            capsLockOn: false,
            now: mondayMorning.addingTimeInterval(30 * 60),
            calendar: calendar,
            configuration: AwakeConfiguration(schedules: [schedule])
        )
        #expect(coordinator.evaluate(facts) == .inactive)
        #expect(!schedule.isSkipped(at: mondayMorning.addingTimeInterval(2 * 60 * 60), calendar: calendar))
    }

    @Test("coordinator calculates the next schedule occurrence to skip")
    func coordinatorCalculatesSkipOccurrence() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let mondayNoon = calendar.date(from: DateComponents(year: 2026, month: 8, day: 3, hour: 12))!
        let schedule = WeeklySchedule(name: "Focus", weekdays: [.monday], startMinutes: 13 * 60, endMinutes: 14 * 60)
        let updated = coordinator.scheduleSkippingNextOccurrence(schedule, now: mondayNoon, calendar: calendar)
        let expected = calendar.date(from: DateComponents(year: 2026, month: 8, day: 3, hour: 13))!
        #expect(updated.skipNextOccurrence)
        #expect(updated.skippedOccurrenceStart == expected)
    }

    @Test("overnight skip covers the after-midnight tail")
    func overnightSkipTail() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let mondayLate = calendar.date(from: DateComponents(year: 2026, month: 8, day: 3, hour: 23))!
        let tuesdayEarly = calendar.date(from: DateComponents(year: 2026, month: 8, day: 4, hour: 0, minute: 30))!
        let schedule = WeeklySchedule(
            name: "Overnight", weekdays: [.monday], startMinutes: 23 * 60, endMinutes: 60,
            skipNextOccurrence: true, skippedOccurrenceStart: mondayLate
        )
        let facts = TriggerFacts(
            capsLockOn: false,
            now: tuesdayEarly,
            calendar: calendar,
            configuration: AwakeConfiguration(schedules: [schedule])
        )
        #expect(coordinator.evaluate(facts) == .inactive)
    }

    @Test("weekly schedules follow the calendar across daylight saving time")
    func daylightSavingSchedule() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        let springForward = calendar.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 3, minute: 30))!
        let schedule = WeeklySchedule(name: "DST", weekdays: [.sunday], startMinutes: 3 * 60, endMinutes: 5 * 60)
        #expect(schedule.isActive(at: springForward, calendar: calendar))
    }

    @Test("app rules match running and frontmost modes")
    func appRuleMatching() {
        let running = AppRule(name: "Render", bundleIdentifier: "com.example.render", match: .whileRunning)
        let frontmost = AppRule(name: "Slides", bundleIdentifier: "com.example.slides", match: .whileFrontmost)
        #expect(running.matches(running: ["com.example.render"], frontmost: nil))
        #expect(frontmost.matches(running: [], frontmost: "com.example.slides"))
        #expect(!frontmost.matches(running: ["com.example.slides"], frontmost: nil))
    }

    @Test("disabled and missing app rules do not create a reason")
    func disabledAppRule() {
        let rule = AppRule(
            name: "Missing", bundleIdentifier: "com.example.missing", match: .whileRunning, enabled: true)
        let facts = TriggerFacts(
            capsLockOn: false,
            now: now,
            runningBundleIdentifiers: ["com.example.missing"],
            missingBundleIdentifiers: ["com.example.missing"],
            configuration: AwakeConfiguration(appRules: [rule])
        )
        #expect(coordinator.evaluate(facts) == .inactive)
    }

    @Test("preset-backed schedules contribute their display policy")
    func presetBackedScheduleMode() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let preset = Preset(name: "Presentation", mode: .systemAndDisplay)
        let date = calendar.date(from: DateComponents(year: 2026, month: 8, day: 3, hour: 9, minute: 30))!
        let schedule = WeeklySchedule(
            name: "Standup", weekdays: [.monday], startMinutes: 9 * 60, endMinutes: 10 * 60, presetID: preset.id
        )
        let facts = TriggerFacts(
            capsLockOn: false,
            now: date,
            calendar: calendar,
            configuration: AwakeConfiguration(presets: [preset], schedules: [schedule])
        )
        #expect(coordinator.evaluate(facts).preventDisplaySleep)
    }

    @Test("end-at timers expose the next plan change")
    func endAtTimerDeadline() {
        let deadline = now.addingTimeInterval(900)
        let timer = TimerSession(title: "Meeting", mode: .systemOnly, expiresAt: deadline)
        #expect(
            coordinator.evaluate(TriggerFacts(capsLockOn: false, now: now, timerSessions: [timer])).nextChangeAt
                == deadline)
    }

    @Test("normalization prunes expired sessions and disables missing apps")
    func normalization() {
        let timer = TimerSession(title: "Expired", mode: .systemOnly, expiresAt: now.addingTimeInterval(-1))
        let rule = AppRule(name: "Missing", bundleIdentifier: "com.example.missing", match: .whileRunning)
        let facts = TriggerFacts(
            capsLockOn: false,
            now: now,
            missingBundleIdentifiers: [rule.bundleIdentifier],
            timerSessions: [timer],
            configuration: AwakeConfiguration(appRules: [rule])
        )
        let normalized = coordinator.normalize(facts)
        #expect(normalized.timerSessions.isEmpty)
        #expect(normalized.configuration.timerSessions.isEmpty)
        #expect(normalized.configuration.appRules.first?.enabled == false)
    }

    @Test("timer planner handles end-at and until-turned-off presets")
    func timerPlannerBranches() {
        let deadline = now.addingTimeInterval(600)
        let endAt = Preset(name: "End", duration: .until(deadline))
        let openEnded = Preset(name: "Open", duration: .untilTurnedOff)
        #expect(TimerPlanner.session(from: endAt, now: now)?.expiresAt == deadline)
        #expect(TimerPlanner.session(from: openEnded, now: now)?.expiresAt == nil)
    }

    @Test("timer planner rejects non-positive deadlines")
    func timerPlannerRejectsInvalidDeadlines() {
        let zeroDuration = Preset(name: "Zero", duration: .fixed(0))
        let pastDeadline = Preset(name: "Past", duration: .until(now.addingTimeInterval(-1)))
        #expect(TimerPlanner.session(from: zeroDuration, now: now) == nil)
        #expect(TimerPlanner.session(from: pastDeadline, now: now) == nil)
    }

    @Test("preset sessions use absolute wall-clock deadlines")
    func presetSessionDeadline() {
        let preset = Preset(name: "Focused", mode: .systemOnly, duration: .fixed(600))
        let session = TimerPlanner.session(from: preset, now: now)
        #expect(session?.expiresAt == now.addingTimeInterval(600))
    }

    @Test("configuration export can be previewed and replaced")
    func configurationImport() throws {
        let temporaryURL = FileManager.default.temporaryDirectory.appendingPathComponent(
            "capsawake-\(UUID().uuidString).json")
        let store = ConfigurationStore(fileURL: temporaryURL)
        let configuration = AwakeConfiguration(presets: [Preset(name: "Exported")])
        let data = try store.exportData(configuration)
        #expect(try store.previewImport(data) == ImportPreview(configuration: configuration))
        #expect(try store.importData(data, mode: .replace, into: AwakeConfiguration()).presets == configuration.presets)
    }

    @Test("configuration store creates its first file atomically")
    func configurationStoreRoundTrip() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            "capsawake-\(UUID().uuidString)", isDirectory: true)
        let url = directory.appendingPathComponent("configuration.json")
        let store = ConfigurationStore(fileURL: url)
        defer { try? FileManager.default.removeItem(at: directory) }
        let configuration = AwakeConfiguration(onboardingCompleted: true)
        try store.save(configuration)
        #expect(try store.load() == configuration)
    }

    @Test("corrupt configuration is quarantined and replaced with defaults")
    func corruptConfigurationRecovery() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            "capsawake-corrupt-\(UUID().uuidString)", isDirectory: true)
        let url = directory.appendingPathComponent("configuration.json")
        let store = ConfigurationStore(fileURL: url)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("not-json".utf8).write(to: url)
        #expect(try store.load() == AwakeConfiguration())
        #expect(FileManager.default.fileExists(atPath: url.path) == false)
        #expect(
            (try? FileManager.default.contentsOfDirectory(atPath: directory.path))?.contains(where: {
                $0.contains("corrupt-")
            })
                == true)
    }

    @Test("newer configuration schemas are rejected")
    func newerConfigurationRejected() throws {
        let store = ConfigurationStore(
            fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("unused.json"))
        let data = Data("{\"schemaVersion\":99}".utf8)
        #expect(throws: ConfigurationStoreError.unsupportedSchema(99)) {
            try store.previewImport(data)
        }
    }

    @Test("invalid imports leave the current configuration unchanged")
    func invalidImportDoesNotMutateCurrentConfiguration() throws {
        let store = ConfigurationStore(
            fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("unused.json"))
        let current = AwakeConfiguration(presets: [Preset(name: "Keep me")])
        #expect(throws: ConfigurationStoreError.invalidImport) {
            try store.importData(Data("not-json".utf8), mode: .replace, into: current)
        }
        #expect(current.presets.map(\.name) == ["Keep me"])
    }

    @Test("configuration merge preserves existing entries")
    func configurationMerge() throws {
        let store = ConfigurationStore(
            fileURL: FileManager.default.temporaryDirectory.appendingPathComponent("unused.json"))
        let existing = AwakeConfiguration(presets: [Preset(name: "Existing")])
        let incoming = AwakeConfiguration(presets: [Preset(name: "Incoming")])
        let merged = try store.importData(try store.exportData(incoming), mode: .merge, into: existing)
        #expect(merged.presets.count == 2)
    }
}
