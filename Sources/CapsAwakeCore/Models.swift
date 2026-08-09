import Foundation

public enum AwakeMode: String, Codable, CaseIterable, Hashable, Sendable {
    case systemOnly
    case systemAndDisplay

    public var keepsDisplayAwake: Bool {
        self == .systemAndDisplay
    }
}

public enum TriggerKind: String, Codable, CaseIterable, Hashable, Sendable {
    case capsLock
    case manual
    case timer
    case schedule
    case appRule
}

public struct TriggerReason: Identifiable, Codable, Hashable, Sendable {
    public let id: String
    public let title: String
    public let kind: TriggerKind
    public let mode: AwakeMode
    public let expiresAt: Date?

    public init(id: String, title: String, kind: TriggerKind, mode: AwakeMode, expiresAt: Date? = nil) {
        self.id = id
        self.title = title
        self.kind = kind
        self.mode = mode
        self.expiresAt = expiresAt
    }
}

public struct AwakePlan: Equatable, Sendable {
    public let preventSystemSleep: Bool
    public let preventDisplaySleep: Bool
    public let activeReasons: [TriggerReason]
    public let warnings: [String]
    public let nextChangeAt: Date?

    public init(
        preventSystemSleep: Bool,
        preventDisplaySleep: Bool,
        activeReasons: [TriggerReason],
        warnings: [String] = [],
        nextChangeAt: Date? = nil
    ) {
        self.preventSystemSleep = preventSystemSleep
        self.preventDisplaySleep = preventDisplaySleep
        self.activeReasons = activeReasons
        self.warnings = warnings
        self.nextChangeAt = nextChangeAt
    }

    public static let inactive = AwakePlan(
        preventSystemSleep: false,
        preventDisplaySleep: false,
        activeReasons: []
    )
}

public enum SessionDuration: Codable, Equatable, Hashable, Sendable {
    case fixed(TimeInterval)
    case until(Date)
    case untilTurnedOff
}

public struct Preset: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var mode: AwakeMode
    public var duration: SessionDuration?
    public var notifyWhenFinished: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        mode: AwakeMode = .systemOnly,
        duration: SessionDuration? = nil,
        notifyWhenFinished: Bool = false
    ) {
        self.id = id
        self.name = name
        self.mode = mode
        self.duration = duration
        self.notifyWhenFinished = notifyWhenFinished
    }

    public static let presentation = Preset(name: "Presentation", mode: .systemAndDisplay, duration: .untilTurnedOff)
    public static let longTask = Preset(name: "Long Task", mode: .systemOnly, duration: .fixed(2 * 60 * 60))
    public static let download = Preset(name: "Download", mode: .systemOnly, duration: .fixed(60 * 60))

    public static var builtIns: [Preset] { [.presentation, .longTask, .download] }
}

public struct ManualSession: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let mode: AwakeMode
    public let expiresAt: Date?

    public init(id: UUID = UUID(), title: String, mode: AwakeMode, expiresAt: Date? = nil) {
        self.id = id
        self.title = title
        self.mode = mode
        self.expiresAt = expiresAt
    }
}

public struct TimerSession: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let mode: AwakeMode
    public let expiresAt: Date?
    public let notifyWhenFinished: Bool

    public init(id: UUID = UUID(), title: String, mode: AwakeMode, expiresAt: Date?, notifyWhenFinished: Bool = false) {
        self.id = id
        self.title = title
        self.mode = mode
        self.expiresAt = expiresAt
        self.notifyWhenFinished = notifyWhenFinished
    }
}

public enum ScheduleWeekday: Int, Codable, CaseIterable, Hashable, Sendable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
}

public struct WeeklySchedule: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var weekdays: Set<ScheduleWeekday>
    public var startMinutes: Int
    public var endMinutes: Int
    public var mode: AwakeMode
    public var presetID: UUID?
    public var skipNextOccurrence: Bool
    public var skippedOccurrenceStart: Date?

    public init(
        id: UUID = UUID(),
        name: String,
        weekdays: Set<ScheduleWeekday>,
        startMinutes: Int,
        endMinutes: Int,
        mode: AwakeMode = .systemOnly,
        presetID: UUID? = nil,
        skipNextOccurrence: Bool = false,
        skippedOccurrenceStart: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.weekdays = weekdays
        self.startMinutes = startMinutes
        self.endMinutes = endMinutes
        self.mode = mode
        self.presetID = presetID
        self.skipNextOccurrence = skipNextOccurrence
        self.skippedOccurrenceStart = skippedOccurrenceStart
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, weekdays, startMinutes, endMinutes, mode, presetID, skipNextOccurrence, skippedOccurrenceStart
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        weekdays = try container.decode(Set<ScheduleWeekday>.self, forKey: .weekdays)
        startMinutes = try container.decode(Int.self, forKey: .startMinutes)
        endMinutes = try container.decode(Int.self, forKey: .endMinutes)
        mode = try container.decode(AwakeMode.self, forKey: .mode)
        presetID = try container.decodeIfPresent(UUID.self, forKey: .presetID)
        skipNextOccurrence = try container.decodeIfPresent(Bool.self, forKey: .skipNextOccurrence) ?? false
        skippedOccurrenceStart = try container.decodeIfPresent(Date.self, forKey: .skippedOccurrenceStart)
    }
}

public enum AppRuleMatch: String, Codable, CaseIterable, Hashable, Sendable {
    case whileRunning
    case whileFrontmost
}

public struct AppRule: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var name: String
    public var bundleIdentifier: String
    public var match: AppRuleMatch
    public var mode: AwakeMode
    public var presetID: UUID?
    public var enabled: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        bundleIdentifier: String,
        match: AppRuleMatch,
        mode: AwakeMode = .systemOnly,
        presetID: UUID? = nil,
        enabled: Bool = true
    ) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.match = match
        self.mode = mode
        self.presetID = presetID
        self.enabled = enabled
    }
}

public struct AwakeConfiguration: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var presets: [Preset]
    public var schedules: [WeeklySchedule]
    public var appRules: [AppRule]
    public var timerSessions: [TimerSession]
    public var onboardingCompleted: Bool
    public var launchAtLogin: Bool
    public var timerEndNotifications: Bool
    public var assertionFailureNotifications: Bool

    public init(
        schemaVersion: Int = currentSchemaVersion,
        presets: [Preset] = Preset.builtIns,
        schedules: [WeeklySchedule] = [],
        appRules: [AppRule] = [],
        timerSessions: [TimerSession] = [],
        onboardingCompleted: Bool = false,
        launchAtLogin: Bool = false,
        timerEndNotifications: Bool = false,
        assertionFailureNotifications: Bool = false
    ) {
        self.schemaVersion = schemaVersion
        self.presets = presets
        self.schedules = schedules
        self.appRules = appRules
        self.timerSessions = timerSessions
        self.onboardingCompleted = onboardingCompleted
        self.launchAtLogin = launchAtLogin
        self.timerEndNotifications = timerEndNotifications
        self.assertionFailureNotifications = assertionFailureNotifications
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, presets, schedules, appRules, timerSessions
        case onboardingCompleted, launchAtLogin, timerEndNotifications, assertionFailureNotifications
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? Self.currentSchemaVersion
        presets = try container.decodeIfPresent([Preset].self, forKey: .presets) ?? Preset.builtIns
        schedules = try container.decodeIfPresent([WeeklySchedule].self, forKey: .schedules) ?? []
        appRules = try container.decodeIfPresent([AppRule].self, forKey: .appRules) ?? []
        timerSessions = try container.decodeIfPresent([TimerSession].self, forKey: .timerSessions) ?? []
        onboardingCompleted = try container.decodeIfPresent(Bool.self, forKey: .onboardingCompleted) ?? false
        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        timerEndNotifications = try container.decodeIfPresent(Bool.self, forKey: .timerEndNotifications) ?? false
        assertionFailureNotifications =
            try container.decodeIfPresent(Bool.self, forKey: .assertionFailureNotifications) ?? false
    }
}

public struct TriggerFacts: Sendable {
    public var capsLockOn: Bool
    public var now: Date
    public var calendar: Calendar
    public var runningBundleIdentifiers: Set<String>
    public var frontmostBundleIdentifier: String?
    public var missingBundleIdentifiers: Set<String>
    public var manualSessions: [ManualSession]
    public var timerSessions: [TimerSession]
    public var configuration: AwakeConfiguration
    public var suppressedTriggerIDs: Set<String>

    public init(
        capsLockOn: Bool,
        now: Date,
        calendar: Calendar = .autoupdatingCurrent,
        runningBundleIdentifiers: Set<String> = [],
        frontmostBundleIdentifier: String? = nil,
        missingBundleIdentifiers: Set<String> = [],
        manualSessions: [ManualSession] = [],
        timerSessions: [TimerSession] = [],
        configuration: AwakeConfiguration = AwakeConfiguration(),
        suppressedTriggerIDs: Set<String> = []
    ) {
        self.capsLockOn = capsLockOn
        self.now = now
        self.calendar = calendar
        self.runningBundleIdentifiers = runningBundleIdentifiers
        self.frontmostBundleIdentifier = frontmostBundleIdentifier
        self.missingBundleIdentifiers = missingBundleIdentifiers
        self.manualSessions = manualSessions
        self.timerSessions = timerSessions
        self.configuration = configuration
        self.suppressedTriggerIDs = suppressedTriggerIDs
    }
}

public enum CoordinatorCommand: Sendable {
    case allowSleepNow
    case resumeAutomation
    case resetSuppression(forTriggerID: String)
}

public struct CoordinatorState: Equatable, Sendable {
    public var suppressedTriggerIDs: Set<String>

    public init(suppressedTriggerIDs: Set<String> = []) {
        self.suppressedTriggerIDs = suppressedTriggerIDs
    }
}

public struct CoordinatorResult: Sendable {
    public let state: CoordinatorState
    public let plan: AwakePlan

    public init(state: CoordinatorState, plan: AwakePlan) {
        self.state = state
        self.plan = plan
    }
}
