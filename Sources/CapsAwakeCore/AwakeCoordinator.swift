import Foundation

public struct AwakeCoordinator: Sendable {
    public init() {}

    public func evaluate(_ facts: TriggerFacts, state: CoordinatorState = CoordinatorState()) -> AwakePlan {
        let normalizedFacts = normalize(facts)
        let reasons = activeReasons(normalizedFacts, state: state)
        let nextChangeAt = reasons.compactMap(\.expiresAt).min()
        return AwakePlan(
            preventSystemSleep: !reasons.isEmpty,
            preventDisplaySleep: reasons.contains(where: { $0.mode.keepsDisplayAwake }),
            activeReasons: reasons,
            nextChangeAt: nextChangeAt
        )
    }

    public func normalize(_ facts: TriggerFacts) -> TriggerFacts {
        var normalized = facts
        normalized.timerSessions = facts.timerSessions.filter { !isExpired($0.expiresAt, now: facts.now) }
        normalized.configuration.timerSessions = normalized.timerSessions
        for index in normalized.configuration.schedules.indices {
            let schedule = normalized.configuration.schedules[index]
            if schedule.skipNextOccurrence,
                schedule.isSkippedOccurrenceComplete(at: facts.now, calendar: facts.calendar)
            {
                normalized.configuration.schedules[index].skipNextOccurrence = false
                normalized.configuration.schedules[index].skippedOccurrenceStart = nil
            }
        }
        for index in normalized.configuration.appRules.indices
        where facts.missingBundleIdentifiers.contains(normalized.configuration.appRules[index].bundleIdentifier) {
            normalized.configuration.appRules[index].enabled = false
        }
        return normalized
    }

    public func scheduleSkippingNextOccurrence(
        _ schedule: WeeklySchedule,
        now: Date,
        calendar: Calendar
    ) -> WeeklySchedule {
        var updated = schedule
        updated.skipNextOccurrence = true
        updated.skippedOccurrenceStart = calendar.date(byAdding: .second, value: 1, to: now)
            .flatMap { schedule.occurrenceStart(at: $0, calendar: calendar) }
        return updated
    }

    public func reconcile(_ state: CoordinatorState, with facts: TriggerFacts) -> CoordinatorState {
        let currentIDs = Set(activeReasons(normalize(facts), state: CoordinatorState()).map(\.id))
        var next = state
        next.suppressedTriggerIDs = state.suppressedTriggerIDs.intersection(currentIDs)
        return next
    }

    public func reduce(
        _ command: CoordinatorCommand,
        facts: TriggerFacts,
        state: CoordinatorState = CoordinatorState()
    ) -> CoordinatorResult {
        var nextState = state
        switch command {
        case .allowSleepNow:
            nextState.suppressedTriggerIDs.formUnion(activeTriggerIDs(facts, state: state))
        case .resumeAutomation:
            nextState.suppressedTriggerIDs.removeAll()
        case .resetSuppression(forTriggerID: let id):
            nextState.suppressedTriggerIDs.remove(id)
        }
        return CoordinatorResult(state: nextState, plan: evaluate(facts, state: nextState))
    }

    private func activeReasons(_ facts: TriggerFacts, state: CoordinatorState) -> [TriggerReason] {
        let capsLock = TriggerReason(
            id: "caps-lock",
            title: "Caps Lock is on",
            kind: .capsLock,
            mode: .systemOnly
        )
        var reasons: [TriggerReason] = []
        if facts.capsLockOn, !isSuppressed(capsLock.id, facts: facts, state: state) {
            reasons.append(capsLock)
        }

        for session in facts.manualSessions where !isExpired(session.expiresAt, now: facts.now) {
            let id = "manual-\(session.id.uuidString)"
            if !isSuppressed(id, facts: facts, state: state) {
                reasons.append(
                    TriggerReason(
                        id: id, title: session.title, kind: .manual, mode: session.mode, expiresAt: session.expiresAt))
            }
        }

        for timer in facts.timerSessions where !isExpired(timer.expiresAt, now: facts.now) {
            let id = "timer-\(timer.id.uuidString)"
            if !isSuppressed(id, facts: facts, state: state) {
                reasons.append(
                    TriggerReason(
                        id: id, title: timer.title, kind: .timer, mode: timer.mode, expiresAt: timer.expiresAt))
            }
        }

        for schedule in facts.configuration.schedules where schedule.isActive(at: facts.now, calendar: facts.calendar) {
            let id = "schedule-\(schedule.id.uuidString)"
            if !schedule.isSkipped(at: facts.now, calendar: facts.calendar),
                !isSuppressed(id, facts: facts, state: state)
            {
                reasons.append(
                    TriggerReason(
                        id: id, title: schedule.name, kind: .schedule,
                        mode: resolvedMode(for: schedule, configuration: facts.configuration)))
            }
        }

        for rule in facts.configuration.appRules
        where rule.enabled
            && !facts.missingBundleIdentifiers.contains(rule.bundleIdentifier)
            && rule.matches(running: facts.runningBundleIdentifiers, frontmost: facts.frontmostBundleIdentifier)
        {
            let id = "app-\(rule.id.uuidString)"
            if !isSuppressed(id, facts: facts, state: state) {
                reasons.append(
                    TriggerReason(
                        id: id, title: rule.name, kind: .appRule,
                        mode: resolvedMode(for: rule, configuration: facts.configuration)))
            }
        }
        return reasons.sorted { lhs, rhs in
            let order: [TriggerKind: Int] = [.manual: 0, .timer: 1, .capsLock: 2, .schedule: 3, .appRule: 4]
            return (order[lhs.kind, default: 99], lhs.title) < (order[rhs.kind, default: 99], rhs.title)
        }
    }

    private func activeTriggerIDs(_ facts: TriggerFacts, state: CoordinatorState) -> Set<String> {
        Set(activeReasons(facts, state: state).map(\.id))
    }

    private func isSuppressed(_ id: String, facts: TriggerFacts, state: CoordinatorState) -> Bool {
        state.suppressedTriggerIDs.contains(id) || facts.suppressedTriggerIDs.contains(id)
    }

    private func isExpired(_ date: Date?, now: Date) -> Bool {
        guard let date else { return false }
        return date <= now
    }

    private func resolvedMode(for schedule: WeeklySchedule, configuration: AwakeConfiguration) -> AwakeMode {
        configuration.presets.first(where: { $0.id == schedule.presetID })?.mode ?? schedule.mode
    }

    private func resolvedMode(for rule: AppRule, configuration: AwakeConfiguration) -> AwakeMode {
        configuration.presets.first(where: { $0.id == rule.presetID })?.mode ?? rule.mode
    }
}

extension WeeklySchedule {
    public func isActive(at date: Date, calendar: Calendar) -> Bool {
        guard !weekdays.isEmpty else { return false }
        let weekday = ScheduleWeekday(rawValue: calendar.component(.weekday, from: date))
        guard let weekday, weekdays.contains(weekday) else {
            if endMinutes <= startMinutes {
                let previousDate = calendar.date(byAdding: .day, value: -1, to: date) ?? date
                let previousWeekday = ScheduleWeekday(rawValue: calendar.component(.weekday, from: previousDate))
                guard let previousWeekday, weekdays.contains(previousWeekday) else { return false }
                return minutesSinceMidnight(date, calendar: calendar) < endMinutes
            }
            return false
        }
        let minutes = minutesSinceMidnight(date, calendar: calendar)
        if startMinutes == endMinutes { return true }
        if endMinutes > startMinutes { return minutes >= startMinutes && minutes < endMinutes }
        return minutes >= startMinutes || minutes < endMinutes
    }

    public func isSkipped(at date: Date, calendar: Calendar) -> Bool {
        guard skipNextOccurrence else { return false }
        guard let skippedOccurrenceStart else { return true }
        guard let occurrence = occurrenceStart(at: date, calendar: calendar) else { return false }
        return calendar.compare(occurrence, to: skippedOccurrenceStart, toGranularity: .minute) == .orderedSame
    }

    public func occurrenceStart(at date: Date, calendar: Calendar) -> Date? {
        for offset in -1...7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: date)) else {
                continue
            }
            guard let weekday = ScheduleWeekday(rawValue: calendar.component(.weekday, from: day)),
                weekdays.contains(weekday)
            else {
                continue
            }
            guard
                let start = calendar.date(
                    bySettingHour: startMinutes / 60, minute: startMinutes % 60, second: 0, of: day)
            else {
                continue
            }
            let endDayOffset = endMinutes <= startMinutes ? 1 : 0
            guard let endDay = calendar.date(byAdding: .day, value: endDayOffset, to: day),
                calendar.date(bySettingHour: endMinutes / 60, minute: endMinutes % 60, second: 0, of: endDay) != nil
            else { continue }
            if date >= start,
                let end = calendar.date(bySettingHour: endMinutes / 60, minute: endMinutes % 60, second: 0, of: endDay),
                date < end
            {
                return start
            }
            if start > date { return start }
        }
        return nil
    }

    public func isSkippedOccurrenceComplete(at date: Date, calendar: Calendar) -> Bool {
        guard skipNextOccurrence, let start = skippedOccurrenceStart else { return false }
        let endDayOffset = endMinutes <= startMinutes ? 1 : 0
        let day = calendar.startOfDay(for: start)
        guard let endDay = calendar.date(byAdding: .day, value: endDayOffset, to: day),
            let end = calendar.date(bySettingHour: endMinutes / 60, minute: endMinutes % 60, second: 0, of: endDay)
        else { return false }
        return date >= end
    }

    private func minutesSinceMidnight(_ date: Date, calendar: Calendar) -> Int {
        calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
    }
}

extension AppRule {
    public func matches(running: Set<String>, frontmost: String?) -> Bool {
        switch match {
        case .whileRunning:
            return running.contains(bundleIdentifier)
        case .whileFrontmost:
            return frontmost == bundleIdentifier
        }
    }
}
