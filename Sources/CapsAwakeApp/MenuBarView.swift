import AppKit
import CapsAwakeCore
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            if let warning = model.warning {
                VStack(alignment: .leading, spacing: 6) {
                    Label(warning, systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Button("Retry") { model.retryPowerAssertion() }
                        .buttonStyle(.borderless)
                }
                .accessibilityElement(children: .contain)
            }
            Divider()
            reasons
            automationSummary
            actions
            Divider()
            footer
        }
        .padding(16)
        .frame(width: 330)
        .sheet(isPresented: Binding(get: { model.isOnboardingPresented }, set: { _ in })) {
            OnboardingView(model: model)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: model.menuBarSymbol)
                .font(.title2)
                .foregroundStyle(model.plan.preventSystemSleep ? .primary : .secondary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(model.statusTitle)
                    .font(.headline)
                Text(statusDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
    }

    private var reasons: some View {
        Group {
            if model.plan.activeReasons.isEmpty {
                Label("Ready for a trigger", systemImage: "checkmark.circle")
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Active reasons")
                        .font(.subheadline.weight(.semibold))
                    ForEach(model.plan.activeReasons) { reason in
                        HStack {
                            Image(systemName: icon(for: reason.kind))
                                .frame(width: 18)
                            Text(reason.title)
                            Spacer()
                            if reason.mode.keepsDisplayAwake {
                                Text("Display")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }

    private var automationSummary: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Automation")
                .font(.subheadline.weight(.semibold))
            Text(
                "\(model.configuration.schedules.count) schedules · \(model.configuration.appRules.count) app rules · \(model.configuration.presets.count) presets"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var actions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Menu {
                ForEach(model.configuration.presets) { preset in
                    Button(preset.name) { model.start(preset) }
                }
                Divider()
                Button("15 Minutes") { model.startCustom(minutes: 15) }
                Button("1 Hour") { model.startCustom(minutes: 60) }
                Button("Custom…") { requestCustomDuration() }
                Button("End at…") { requestEndTime() }
                Button("Until Turned Off") {
                    model.start(Preset(name: "Manual session", mode: .systemOnly, duration: .untilTurnedOff))
                }
            } label: {
                Label("Start a session", systemImage: "play.fill")
            }
            .menuStyle(.borderlessButton)

            if model.plan.activeReasons.isEmpty || model.automationPaused {
                Button {
                    model.resumeAutomation()
                } label: {
                    Label("Resume Automation", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .disabled(!model.automationPaused)
            } else {
                Button {
                    model.allowSleepNow()
                } label: {
                    Label("Allow Sleep Now", systemImage: "moon.zzz")
                }
                .buttonStyle(.borderless)
            }

            if !model.manualSessions.isEmpty || !model.timerSessions.isEmpty {
                Button("Stop Manual Sessions") { model.stopAllSessions() }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var footer: some View {
        HStack {
            SettingsLink {
                Label("Settings", systemImage: "gearshape")
            }
            .buttonStyle(.borderless)
            Spacer()
            Button("About") { showAbout() }
                .buttonStyle(.borderless)
            Spacer()
            Button("Quit") { model.quit() }
                .buttonStyle(.borderless)
        }
    }

    private func icon(for kind: TriggerKind) -> String {
        switch kind {
        case .capsLock: return "capslock.fill"
        case .manual: return "hand.tap"
        case .timer: return "timer"
        case .schedule: return "calendar"
        case .appRule: return "app.badge"
        }
    }

    private var statusDetail: String {
        if model.plan.preventSystemSleep {
            if let nextChangeAt = model.plan.nextChangeAt {
                return "Until \(nextChangeAt.formatted(date: .omitted, time: .shortened))"
            }
            return "Sleep prevention is active"
        }
        return "Nothing is keeping the Mac awake"
    }

    private func requestCustomDuration() {
        let alert = NSAlert()
        alert.messageText = "Custom session"
        alert.informativeText = "How many minutes should CapsAwake stay awake?"
        let field = NSTextField(string: "30")
        field.frame.size = NSSize(width: 220, height: 24)
        alert.accessoryView = field
        alert.addButton(withTitle: "Start")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn, let minutes = Int(field.stringValue), minutes > 0 else {
            return
        }
        model.startCustom(minutes: minutes)
    }

    private func requestEndTime() {
        let alert = NSAlert()
        alert.messageText = "End-at time"
        alert.informativeText = "Enter a local time in 24-hour format (for example, 18:30)."
        let field = NSTextField(string: "18:00")
        field.frame.size = NSSize(width: 220, height: 24)
        alert.accessoryView = field
        alert.addButton(withTitle: "Start")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        guard let parsed = formatter.date(from: field.stringValue) else { return }
        let components = Calendar.current.dateComponents([.hour, .minute], from: parsed)
        guard
            let today = Calendar.current.date(
                bySettingHour: components.hour ?? 0, minute: components.minute ?? 0, second: 0, of: Date())
        else {
            return
        }
        let end = today > Date() ? today : Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        model.startUntil(date: end)
    }

    private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "CapsAwake"
        alert.informativeText =
            "A quiet, open-source way to keep your Mac awake.\n\nMIT licensed · no analytics · no keyboard monitoring"
        alert.addButton(withTitle: "Done")
        alert.runModal()
    }
}
