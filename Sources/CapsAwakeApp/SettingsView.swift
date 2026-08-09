import AppKit
import CapsAwakeCore
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        TabView {
            general
                .tabItem { Label("General", systemImage: "gearshape") }
            presets
                .tabItem { Label("Presets", systemImage: "square.grid.2x2") }
            schedules
                .tabItem { Label("Schedules", systemImage: "calendar") }
            appRules
                .tabItem { Label("App Rules", systemImage: "app.badge") }
            advanced
                .tabItem { Label("Advanced", systemImage: "slider.horizontal.3") }
        }
        .padding(20)
        .frame(width: 660, height: 430)
    }

    private var general: some View {
        Form {
            Section("Behavior") {
                Text("Caps Lock is a passive trigger. When it is on, CapsAwake prevents idle system sleep.")
                    .foregroundStyle(.secondary)
                Toggle(
                    "Launch at Login",
                    isOn: Binding(
                        get: { model.configuration.launchAtLogin },
                        set: { model.setLaunchAtLogin($0) }
                    ))
                Toggle(
                    "Notify when timers end",
                    isOn: Binding(
                        get: { model.configuration.timerEndNotifications },
                        set: { model.setTimerEndNotifications($0) }
                    ))
                Toggle(
                    "Notify when a power assertion fails",
                    isOn: Binding(
                        get: { model.configuration.assertionFailureNotifications },
                        set: { model.setAssertionFailureNotifications($0) }
                    ))
            }
            Section("Privacy") {
                Label(
                    "CapsAwake reads the system's logical modifier state and does not monitor keystrokes.",
                    systemImage: "lock.shield"
                )
                .foregroundStyle(.secondary)
            }
        }
    }

    private var presets: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Presets").font(.title2.weight(.semibold))
                Spacer()
                Button("Add Preset", systemImage: "plus") { model.addPreset() }
            }
            List {
                ForEach(model.configuration.presets) { preset in
                    HStack {
                        Image(systemName: preset.mode.keepsDisplayAwake ? "sun.max" : "moon")
                        TextField(
                            "Preset name",
                            text: Binding(
                                get: { preset.name },
                                set: {
                                    model.updatePreset(
                                        Preset(
                                            id: preset.id, name: $0, mode: preset.mode, duration: preset.duration,
                                            notifyWhenFinished: preset.notifyWhenFinished))
                                }
                            )
                        )
                        .textFieldStyle(.plain)
                        Picker(
                            "Display",
                            selection: Binding(
                                get: { preset.mode },
                                set: {
                                    model.updatePreset(
                                        Preset(
                                            id: preset.id, name: preset.name, mode: $0, duration: preset.duration,
                                            notifyWhenFinished: preset.notifyWhenFinished))
                                }
                            )
                        ) {
                            Text("Screen may sleep").tag(AwakeMode.systemOnly)
                            Text("Keep screen awake").tag(AwakeMode.systemAndDisplay)
                        }
                        .labelsHidden()
                        .frame(width: 150)
                        Menu {
                            Button("15 minutes") { updatePresetDuration(preset, duration: .fixed(15 * 60)) }
                            Button("1 hour") { updatePresetDuration(preset, duration: .fixed(60 * 60)) }
                            Button("2 hours") { updatePresetDuration(preset, duration: .fixed(2 * 60 * 60)) }
                            Button("Until turned off") { updatePresetDuration(preset, duration: .untilTurnedOff) }
                            Button("End at 6:00 PM") {
                                let end =
                                    Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
                                updatePresetDuration(preset, duration: .until(end))
                            }
                        } label: {
                            Text(durationLabel(preset.duration))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .menuStyle(.borderlessButton)
                        Toggle(
                            "Notify",
                            isOn: Binding(
                                get: { preset.notifyWhenFinished },
                                set: {
                                    model.updatePreset(
                                        Preset(
                                            id: preset.id, name: preset.name, mode: preset.mode,
                                            duration: preset.duration,
                                            notifyWhenFinished: $0))
                                }
                            )
                        )
                        .labelsHidden()
                        .help("Notify when this preset's timer ends")
                        Spacer()
                        Button("Delete", systemImage: "trash") { model.removePreset(preset) }
                            .labelStyle(.iconOnly)
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Delete \(preset.name)")
                    }
                }
            }
        }
    }

    private var schedules: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Schedules").font(.title2.weight(.semibold))
                Spacer()
                Button("Add Schedule", systemImage: "plus") { model.addSchedule() }
            }
            if model.configuration.schedules.isEmpty {
                ContentUnavailableView(
                    "No schedules yet", systemImage: "calendar",
                    description: Text("Create a weekly schedule when you want CapsAwake to work on a routine."))
            } else {
                List {
                    ForEach(model.configuration.schedules) { schedule in
                        HStack {
                            Image(systemName: "calendar")
                            VStack(alignment: .leading) {
                                TextField(
                                    "Schedule name",
                                    text: Binding(
                                        get: { schedule.name },
                                        set: {
                                            var updated = schedule
                                            updated.name = $0
                                            model.updateSchedule(updated)
                                        }
                                    ))
                                Text(scheduleDescription(schedule))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Picker(
                                "Display",
                                selection: Binding(
                                    get: { schedule.mode },
                                    set: {
                                        var updated = schedule
                                        updated.mode = $0
                                        model.updateSchedule(updated)
                                    }
                                )
                            ) {
                                Text("System").tag(AwakeMode.systemOnly)
                                Text("Display").tag(AwakeMode.systemAndDisplay)
                            }
                            .labelsHidden()
                            Menu("Weekdays") {
                                ForEach(ScheduleWeekday.allCases, id: \.self) { weekday in
                                    Button {
                                        model.toggleWeekday(weekday, for: schedule)
                                    } label: {
                                        Label(
                                            weekdayName(weekday),
                                            systemImage: schedule.weekdays.contains(weekday) ? "checkmark" : "circle"
                                        )
                                    }
                                }
                            }
                            Stepper(
                                timeLabel(schedule.startMinutes),
                                value: Binding(
                                    get: { schedule.startMinutes },
                                    set: {
                                        var updated = schedule
                                        updated.startMinutes = min(max($0, 0), 23 * 60 + 59)
                                        model.updateSchedule(updated)
                                    }
                                ),
                                in: 0...(23 * 60 + 59),
                                step: 30
                            )
                            .labelsHidden()
                            Stepper(
                                timeLabel(schedule.endMinutes),
                                value: Binding(
                                    get: { schedule.endMinutes },
                                    set: {
                                        var updated = schedule
                                        updated.endMinutes = min(max($0, 0), 23 * 60 + 59)
                                        model.updateSchedule(updated)
                                    }
                                ),
                                in: 0...(23 * 60 + 59),
                                step: 30
                            )
                            .labelsHidden()
                            Menu("Preset") {
                                Button("Schedule policy") {
                                    var updated = schedule
                                    updated.presetID = nil
                                    model.updateSchedule(updated)
                                }
                                ForEach(model.configuration.presets) { preset in
                                    Button(preset.name) {
                                        var updated = schedule
                                        updated.presetID = preset.id
                                        model.updateSchedule(updated)
                                    }
                                }
                            }
                            Spacer()
                            Button("Skip Next") { model.skipNext(schedule) }
                                .buttonStyle(.borderless)
                            Button("Delete", systemImage: "trash") { model.removeSchedule(schedule) }
                                .labelStyle(.iconOnly)
                                .buttonStyle(.borderless)
                                .accessibilityLabel("Delete \(schedule.name)")
                        }
                    }
                }
            }
        }
    }

    private var appRules: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("App Rules").font(.title2.weight(.semibold))
                Spacer()
                Button("Add Rule", systemImage: "plus") { chooseAppForRule() }
            }
            if model.configuration.appRules.isEmpty {
                ContentUnavailableView(
                    "No app rules yet", systemImage: "app.badge",
                    description: Text(
                        "Choose an installed app and CapsAwake can stay awake while it runs or is frontmost."))
            } else {
                List {
                    ForEach(model.configuration.appRules) { rule in
                        HStack {
                            Image(systemName: "app.badge")
                            VStack(alignment: .leading) {
                                TextField(
                                    "Rule name",
                                    text: Binding(
                                        get: { rule.name },
                                        set: {
                                            var updated = rule
                                            updated.name = $0
                                            model.updateAppRule(updated)
                                        }
                                    ))
                                Text(rule.bundleIdentifier)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if !model.isAppAvailable(rule) {
                                    Text("App not found · relink required")
                                        .font(.caption2)
                                        .foregroundStyle(.orange)
                                }
                            }
                            Spacer()
                            Picker(
                                "Match",
                                selection: Binding(
                                    get: { rule.match },
                                    set: {
                                        var updated = rule
                                        updated.match = $0
                                        model.updateAppRule(updated)
                                    }
                                )
                            ) {
                                Text("Running").tag(AppRuleMatch.whileRunning)
                                Text("Frontmost").tag(AppRuleMatch.whileFrontmost)
                            }
                            .labelsHidden()
                            Picker(
                                "Display",
                                selection: Binding(
                                    get: { rule.mode },
                                    set: {
                                        var updated = rule
                                        updated.mode = $0
                                        model.updateAppRule(updated)
                                    }
                                )
                            ) {
                                Text("System").tag(AwakeMode.systemOnly)
                                Text("Display").tag(AwakeMode.systemAndDisplay)
                            }
                            .labelsHidden()
                            Menu("Preset") {
                                Button("Rule policy") {
                                    var updated = rule
                                    updated.presetID = nil
                                    model.updateAppRule(updated)
                                }
                                ForEach(model.configuration.presets) { preset in
                                    Button(preset.name) {
                                        var updated = rule
                                        updated.presetID = preset.id
                                        model.updateAppRule(updated)
                                    }
                                }
                            }
                            Toggle(
                                "Enabled",
                                isOn: Binding(
                                    get: { rule.enabled },
                                    set: {
                                        var updated = rule
                                        updated.enabled = $0
                                        model.updateAppRule(updated)
                                    }
                                )
                            )
                            .labelsHidden()
                            if !model.isAppAvailable(rule) {
                                Button("Relink") { relink(rule) }
                                    .buttonStyle(.borderless)
                            }
                            Button("Delete", systemImage: "trash") { model.removeAppRule(rule) }
                                .labelStyle(.iconOnly)
                                .buttonStyle(.borderless)
                                .accessibilityLabel("Delete \(rule.name)")
                        }
                    }
                }
            }
        }
    }

    private var advanced: some View {
        Form {
            Section("Power policy") {
                Text(
                    "CapsAwake uses public macOS power assertions. They cover idle sleep only; explicit or safety-driven sleep remains authoritative."
                )
                .foregroundStyle(.secondary)
            }
            Section("Configuration") {
                HStack {
                    Button("Export JSON") { exportConfiguration() }
                    Button("Import JSON") { importConfiguration() }
                }
                Text("Exports are versioned JSON. Imports are previewed before you choose merge or replace.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let warning = model.warning {
                Section("Attention") {
                    Label(warning, systemImage: "exclamationmark.triangle")
                }
            }
        }
    }

    private func durationLabel(_ duration: SessionDuration?) -> String {
        guard let duration else { return "Until turned off" }
        switch duration {
        case .fixed(let seconds): return "\(Int(seconds / 60)) min"
        case .until(let date): return date.formatted(date: .omitted, time: .shortened)
        case .untilTurnedOff: return "Until turned off"
        }
    }

    private func updatePresetDuration(_ preset: Preset, duration: SessionDuration) {
        model.updatePreset(
            Preset(
                id: preset.id, name: preset.name, mode: preset.mode, duration: duration,
                notifyWhenFinished: preset.notifyWhenFinished))
    }

    private func scheduleDescription(_ schedule: WeeklySchedule) -> String {
        let days = schedule.weekdays.sorted { $0.rawValue < $1.rawValue }.map(weekdayName).joined(separator: ", ")
        return "\(days) · \(timeLabel(schedule.startMinutes))–\(timeLabel(schedule.endMinutes))"
    }

    private func weekdayName(_ weekday: ScheduleWeekday) -> String {
        switch weekday {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }

    private func timeLabel(_ minutes: Int) -> String {
        let hour = minutes / 60
        let minute = minutes % 60
        return String(format: "%02d:%02d", hour, minute)
    }

    private func exportConfiguration() {
        guard let data = model.exportConfiguration() else { return }
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "CapsAwake-configuration.json"
        panel.allowedContentTypes = [.json]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        try? data.write(to: url, options: [.atomic])
    }

    private func importConfiguration() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url, let data = try? Data(contentsOf: url) else { return }
        model.previewAndImport(data)
    }

    private func chooseAppForRule() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url, let bundle = Bundle(url: url),
            let bundleIdentifier = bundle.bundleIdentifier
        else { return }
        model.addAppRule(
            name: bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                ?? url.deletingPathExtension().lastPathComponent,
            bundleIdentifier: bundleIdentifier
        )
    }

    private func relink(_ rule: AppRule) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url, let bundle = Bundle(url: url),
            let bundleIdentifier = bundle.bundleIdentifier
        else { return }
        var updated = rule
        updated.bundleIdentifier = bundleIdentifier
        updated.enabled = true
        model.updateAppRule(updated)
    }
}
