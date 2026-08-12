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
        }
        .padding(20)
        .frame(width: 660, height: 430)
    }

    private var general: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                settingsSection(
                    title: "Behavior",
                    detail: "Caps Lock is a passive trigger. When it is on, CapsAwake prevents idle system sleep."
                ) {
                    VStack(alignment: .leading, spacing: 0) {
                        settingToggle(
                            title: "Launch at Login",
                            detail: "Start CapsAwake automatically when you sign in.",
                            isOn: Binding(
                                get: { model.configuration.launchAtLogin },
                                set: { model.setLaunchAtLogin($0) }
                            )
                        )
                        Divider()
                        settingToggle(
                            title: "Timer notifications",
                            detail: "Let you know when a timed session ends.",
                            isOn: Binding(
                                get: { model.configuration.timerEndNotifications },
                                set: { model.setTimerEndNotifications($0) }
                            )
                        )
                        Divider()
                        settingToggle(
                            title: "Power assertion alerts",
                            detail: "Tell you when macOS could not apply sleep prevention.",
                            isOn: Binding(
                                get: { model.configuration.assertionFailureNotifications },
                                set: { model.setAssertionFailureNotifications($0) }
                            )
                        )
                    }
                }
                settingsSection(title: "Privacy", detail: nil) {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.secondary)
                            .frame(width: 22)
                        Text("CapsAwake reads the system's logical modifier state and does not monitor keystrokes.")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                settingsSection(
                    title: "Configuration",
                    detail: "Back up or move your settings as versioned JSON."
                ) {
                    HStack(spacing: 10) {
                        Button("Export JSON", systemImage: "square.and.arrow.up") { exportConfiguration() }
                        Button("Import JSON", systemImage: "square.and.arrow.down") { importConfiguration() }
                    }
                    .padding(8)
                }
            }
            .frame(maxWidth: 560, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func settingsSection<Content: View>(
        title: String,
        detail: String?,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 15, weight: .medium))
            if let detail {
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            content()
                .padding(4)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func settingToggle(title: String, detail: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
        }
        .toggleStyle(.switch)
        .controlSize(.small)
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }

    private func emptyState(title: String, detail: String, symbol: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 38, height: 38)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var presets: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Presets").font(.system(size: 20, weight: .medium))
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
                                let today =
                                    Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
                                let end =
                                    today > Date()
                                    ? today
                                    : Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var schedules: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Schedules").font(.system(size: 20, weight: .medium))
                Spacer()
                Button("Add Schedule", systemImage: "plus") { model.addSchedule() }
            }
            if model.configuration.schedules.isEmpty {
                emptyState(
                    title: "No schedules yet",
                    detail: "Create a weekly schedule when you want CapsAwake to work on a routine.",
                    symbol: "calendar"
                )
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var appRules: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("App Rules").font(.system(size: 20, weight: .medium))
                Spacer()
                Button("Add Rule", systemImage: "plus") { chooseAppForRule() }
            }
            if model.configuration.appRules.isEmpty {
                emptyState(
                    title: "No app rules yet",
                    detail: "Choose an installed app and CapsAwake can stay awake while it runs or is frontmost.",
                    symbol: "app.badge"
                )
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
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
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
