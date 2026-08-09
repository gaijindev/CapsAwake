import SwiftUI

struct OnboardingView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image(systemName: "capslock.fill")
                .font(.system(size: 34))
                .accessibilityHidden(true)
            Text("Meet CapsAwake")
                .font(.largeTitle.weight(.semibold))
            Text(
                "Turn Caps Lock on when you want your Mac to stay awake. CapsAwake prevents idle system sleep by default, while allowing the display to sleep unless a session asks for it."
            )
            .foregroundStyle(.secondary)
            Label("No Accessibility or Input Monitoring permission", systemImage: "hand.raised")
            Label("Explicit Sleep, lid close, and safety protections still win", systemImage: "checkmark.shield")
            Label("Use the menu bar to pause automation at any time", systemImage: "pause.circle")
            HStack {
                Spacer()
                Button("Get Started") { model.completeOnboarding() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(28)
        .frame(width: 430)
    }
}
