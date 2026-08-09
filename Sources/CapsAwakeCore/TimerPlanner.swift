import Foundation

public enum TimerPlanner {
    public static func session(from preset: Preset, now: Date) -> TimerSession? {
        guard let duration = preset.duration else { return nil }
        let expiresAt: Date?
        switch duration {
        case .fixed(let seconds):
            expiresAt = now.addingTimeInterval(seconds)
        case .until(let date):
            expiresAt = date
        case .untilTurnedOff:
            expiresAt = nil
        }
        return TimerSession(
            title: preset.name,
            mode: preset.mode,
            expiresAt: expiresAt,
            notifyWhenFinished: preset.notifyWhenFinished
        )
    }
}
