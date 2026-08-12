import AppKit
import CapsAwakeCore
import SwiftUI

struct MenuBarView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if let warning = model.warning {
                warningCard(warning)
                    .padding(.top, 14)
            }
            VStack(alignment: .leading, spacing: 18) {
                reasons
                actions
                automationSummary
            }
            .padding(.top, 20)
            Divider()
                .padding(.top, 18)
            footer
                .padding(.top, 10)
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .frame(width: 360)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(.white.opacity(0.12), lineWidth: 0.5)
        }
        .sheet(isPresented: Binding(get: { model.isOnboardingPresented }, set: { _ in })) {
            OnboardingView(model: model)
        }
    }

    private func warningCard(_ warning: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 7) {
                Text("Needs attention")
                    .font(.system(size: 13, weight: .medium))
                Text(warning)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Retry") { model.retryPowerAssertion() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityElement(children: .contain)
    }

    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(statusColor.opacity(0.18))
                    .frame(width: 40, height: 40)
                Image(systemName: model.menuBarSymbol)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(statusColor)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(model.statusTitle)
                    .font(.system(size: 18, weight: .medium))
                Text(statusDetail)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 10)
            VStack(alignment: .trailing, spacing: 4) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 7, height: 7)
                Text(statusLabel)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var reasons: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Active reasons", symbol: "bolt.fill")
            if model.plan.activeReasons.isEmpty {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ready for a trigger")
                            .font(.system(size: 13, weight: .medium))
                        Text("Caps Lock, timers, and automations are standing by.")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(model.plan.activeReasons) { reason in
                        HStack(spacing: 10) {
                            Image(systemName: icon(for: reason.kind))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(statusColor)
                                .frame(width: 18)
                            Text(reason.title)
                                .font(.system(size: 13, weight: .medium))
                            Spacer(minLength: 8)
                            if reason.mode.keepsDisplayAwake {
                                Label("Display", systemImage: "sun.max.fill")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 3)
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }

    private var automationSummary: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Automation", symbol: "wand.and.stars")
            HStack(spacing: 0) {
                automationMetric("Schedules", count: model.configuration.schedules.count, symbol: "calendar")
                Divider()
                    .frame(height: 28)
                automationMetric("App rules", count: model.configuration.appRules.count, symbol: "app.badge")
                Divider()
                    .frame(height: 28)
                automationMetric("Presets", count: model.configuration.presets.count, symbol: "square.stack.3d.up")
            }
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private var actions: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("Manual control", symbol: "hand.tap")
            if model.automationPaused {
                Button {
                    model.resumeAutomation()
                } label: {
                    actionRow(title: "Resume automation", detail: "Turn triggers back on", symbol: "arrow.clockwise")
                }
                .buttonStyle(.plain)
            } else if !model.plan.activeReasons.isEmpty {
                Button {
                    model.allowSleepNow()
                } label: {
                    actionRow(title: "Allow sleep now", detail: "Pause active triggers", symbol: "moon.zzz")
                }
                .buttonStyle(.plain)
            }

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
                    .font(.system(size: 13, weight: .medium))
            }
            .menuStyle(.borderedButton)
            .controlSize(.large)

            if !model.manualSessions.isEmpty || !model.timerSessions.isEmpty {
                Button {
                    model.stopAllSessions()
                } label: {
                    Label("Stop manual sessions", systemImage: "stop.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.top, 2)
            }
        }
    }

    private var footer: some View {
        HStack(spacing: 4) {
            SettingsLink {
                footerLabel("Settings", symbol: "gearshape")
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            Button {
                showAbout()
            } label: {
                footerLabel("About", symbol: "info.circle")
            }
            .buttonStyle(.plain)
            Spacer()
            Button {
                model.quit()
            } label: {
                footerLabel("Quit", symbol: "power")
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.secondary)
    }

    private func sectionHeader(_ title: String, symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.secondary)
    }

    private func automationMetric(_ title: String, count: Int, symbol: String) -> some View {
        VStack(spacing: 3) {
            Image(systemName: symbol)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            Text("\(count)")
                .font(.system(size: 15, weight: .medium))
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func actionRow(title: String, detail: String, symbol: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .medium))
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(detail)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func footerLabel(_ title: String, symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .font(.system(size: 11, weight: .medium))
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

    private var statusLabel: String {
        if model.automationPaused { return "PAUSED" }
        return model.plan.activeReasons.isEmpty ? "READY" : "ACTIVE"
    }

    private var statusColor: Color {
        if model.automationPaused { return .orange }
        return model.plan.activeReasons.isEmpty ? .secondary : .green
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
