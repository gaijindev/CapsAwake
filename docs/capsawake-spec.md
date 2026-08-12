# CapsAwake — Product Specification

Status: ready-for-agent  
Working name: CapsAwake  
Target: macOS 14+, Universal binary (Apple silicon and supported Intel Macs)  
Distribution: signed and notarized GitHub releases, followed by a Homebrew Cask

## Problem Statement

Mac users sometimes need their computer to remain awake for a download, render, presentation, meeting, upload, remote session, or other long-running task. Existing “caffeine” utilities solve this with a manual toggle, but the user wants a more physical, immediate control: when Caps Lock is enabled, the Mac should stay awake; when Caps Lock is disabled, normal sleep behavior should return.

The utility must also support planned work without turning into a confusing automation dashboard. Timers, recurring schedules, app-based rules, and presets should be available while the menu-bar experience remains calm, native, and understandable. The app must be trustworthy as open-source software: no analytics, no account, no unnecessary permissions, clean seams, deterministic tests, and clear release artifacts.

## Solution

CapsAwake is a native SwiftUI menu-bar utility with no regular Dock presence. It passively reads the Mac’s logical Caps Lock state and combines that trigger with independent timers, weekly schedules, app rules, and manual sessions.

Each active trigger contributes a desired awake plan. System-sleep prevention is active when any trigger requests it. Display-sleep prevention is active when at least one active trigger requests it. The default policy prevents idle system sleep while allowing the display to sleep; each timer, schedule, app rule, or preset may override that display policy.

The menu-bar popover shows the current overall state, every active reason, quick timer and preset actions, automation summaries, and a safe “Allow Sleep Now” action. A native Settings window manages General, Presets, Schedules, and App Rules; configuration backup and restore live in General. The first-run experience explains Caps Lock behavior, the display-sleep tradeoff, privacy, and optional Launch at Login.

## User Stories

1. As a Mac user, I want Caps Lock to keep my Mac awake, so that I can use a familiar physical state instead of hunting for a separate toggle.
2. As a Mac user, I want normal sleep behavior to return when Caps Lock turns off, so that I do not leave my Mac awake accidentally.
3. As a Mac user, I want CapsAwake to reflect the real logical Caps Lock state, so that the keyboard LED, typing behavior, menu-bar state, and awake behavior agree.
4. As a Mac user, I want CapsAwake to work with built-in, USB, and Bluetooth keyboards, so that I do not need a special keyboard.
5. As a privacy-conscious user, I want CapsAwake to avoid Accessibility and Input Monitoring permissions, so that a simple sleep utility does not receive unnecessary keyboard access.
6. As a Mac user, I want to prevent idle system sleep while allowing the display to sleep by default, so that background work continues without unnecessarily keeping the screen lit.
7. As a Mac user, I want a trigger to keep the display awake when necessary, so that presentations, meetings, and visual monitoring remain visible.
8. As a Mac user, I want active display requirements to take precedence when triggers overlap, so that a presentation rule cannot be accidentally weakened by another trigger.
9. As a Mac user, I want explicit Apple-menu sleep, lid closure, low-battery protection, and thermal protection to remain authoritative, so that CapsAwake cannot create an unsafe sleep lock.
10. As a Mac user, I want a timer for a fixed duration, so that I can keep the Mac awake for a bounded task.
11. As a Mac user, I want a timer that ends at a chosen clock time, so that I can align awake behavior with a meeting or work deadline.
12. As a Mac user, I want an “until turned off” session, so that I can run an open-ended task without inventing a duration.
13. As a Mac user, I want timers to use wall-clock time, so that explicit sleep does not unexpectedly extend a timed session.
14. As a Mac user, I want recurring weekday schedules, so that regular work periods do not require manual activation.
15. As a Mac user, I want schedules to support overnight ranges, so that a session can cross midnight naturally.
16. As a traveler, I want schedules to follow the Mac’s current local timezone, so that a “9:00 AM” schedule remains understandable when I move locations.
17. As a Mac user, I want daylight-saving transitions to follow the system calendar, so that skipped times are skipped and repeated times do not activate twice.
18. As a Mac user, I want to skip the next schedule occurrence, so that I can handle a holiday or exception without editing the recurring rule.
19. As a Mac user, I want an app rule that is active while an app is running, so that downloads, renders, and background jobs can complete.
20. As a Mac user, I want an app rule that is active while an app is frontmost, so that presentations and focused work can remain visible.
21. As a Mac user, I want app rules to identify apps by bundle identifier, so that a renamed or relocated app is not silently confused with another app.
22. As a Mac user, I want missing app rules to remain visible and disabled, so that I can relink the intended app instead of losing configuration.
23. As a Mac user, I want any active trigger to be sufficient to keep the Mac awake, so that one finished task does not cancel another task still in progress.
24. As a Mac user, I want to see every active awake reason, so that I understand why the Mac is currently being kept awake.
25. As a Mac user, I want a safe “Allow Sleep Now” action, so that I can immediately release awake assertions without deleting my rules.
26. As a Mac user, I want “Allow Sleep Now” to suppress currently active conditions until they reset, so that an active Caps Lock or schedule does not immediately reassert itself.
27. As a Mac user, I want a preset for a reusable awake policy, so that common sessions take one click.
28. As a Mac user, I want built-in Presentation, Long Task, and Download presets, so that the first launch is useful without requiring configuration.
29. As a Mac user, I want presets to be editable and deletable, so that the defaults do not constrain my workflow.
30. As a Mac user, I want schedules and app rules to reference presets, so that one policy can be maintained in one place.
31. As a Mac user, I want edits to a preset to affect future sessions and attached rules, so that configuration changes remain consistent.
32. As a Mac user, I want a running session to keep a snapshot of its original preset settings, so that changing a preset does not unexpectedly alter work already in progress.
33. As a Mac user, I want to start a quick timer from the menu bar, so that common actions do not require opening Settings.
34. As a Mac user, I want to choose Custom or Until Turned Off from the menu bar, so that quick actions do not limit advanced use.
35. As a Mac user, I want the menu-bar item to show an unmistakable active state, so that I can confirm the Mac’s current policy at a glance.
36. As a Mac user, I want the menu-bar icon to work in light and dark menu bars, so that the app feels native in either appearance.
37. As a Mac user, I want the menu-bar popover to lead with current status and active reasons, so that the most important information is immediately visible.
38. As a Mac user, I want Settings to contain General, Presets, Schedules, and App Rules, so that configuration stays organized without an expert-only section.
39. As a first-time user, I want one concise onboarding explanation, so that I understand Caps Lock control, automation, display sleep, privacy, and Launch at Login.
40. As a Mac user, I want Launch at Login to be opt-in, so that CapsAwake never changes my login items silently.
41. As a Mac user, I want routine session starts to remain quiet, so that the utility does not interrupt my work with notifications.
42. As a Mac user, I want to optionally receive a notification when a timer ends, so that I can know when a bounded session has completed.
43. As a Mac user, I want an optional notification when macOS cannot maintain a requested power assertion, so that CapsAwake never silently claims protection it does not have.
44. As a Mac user, I want clear warnings when an assertion fails, so that I can retry or change the policy.
45. As a Mac user, I want local settings to survive a relaunch, so that schedules, rules, and presets do not disappear.
46. As a Mac user, I want unexpired timed sessions to recover after an unexpected relaunch, so that a crash does not silently abandon a long-running task.
47. As a Mac user, I want an explicit Quit to cancel manual and timed sessions, so that quitting is a reliable way to release temporary behavior.
48. As a Mac user, I want to export and import my configuration as versioned JSON, so that I can back up or move my setup.
49. As a Mac user, I want invalid or newer configuration files rejected without changing current settings, so that an import cannot corrupt my setup.
50. As a Mac user, I want to choose whether a valid import replaces or merges settings, so that backup restoration and selective sharing are both possible.
51. As a VoiceOver user, I want every state, control, warning, and icon to have an accessible label, so that the app is fully usable without sight.
52. As a keyboard user, I want Settings and the popover to support predictable keyboard navigation and visible focus, so that I do not need a pointing device.
53. As a user who prefers reduced motion, I want state changes to remain understandable without animation, so that accessibility settings are respected.
54. As a contributor, I want the policy engine to be testable without a real keyboard or power state, so that I can make safe changes quickly.
55. As a contributor, I want the repository to explain setup, architecture, testing, release, and permissions, so that I can contribute without private context.
56. As a contributor, I want pull requests to run the same formatting, checks, tests, and build used by maintainers, so that failures are reproducible.
57. As an open-source user, I want no accounts, telemetry, analytics, or network dependency, so that the app remains auditable and private.
58. As an open-source user, I want signed and notarized release artifacts with checksums, so that downloaded builds are trustworthy.
59. As a Homebrew user, I want a matching Homebrew Cask, so that installation and upgrades are convenient.
60. As a maintainer, I want Semantic Versioning and a documented support policy, so that compatibility expectations are clear.

## Implementation Decisions

- **Platform and app shape:** Build a native SwiftUI macOS menu-bar app targeting macOS 14 or newer as a Universal binary. Use AppKit only for platform APIs that SwiftUI does not provide. The app has no regular Dock presence; Settings and About open only when requested.
- **Working identity:** Use CapsAwake as the working product and package name. Validate repository, bundle identifier, and trademark availability before the first public release.
- **Primary seam:** The highest test seam is a pure `AwakeCoordinator` module. Its interface accepts current trigger facts, time/calendar context, persisted configuration, and user commands; it returns an `AwakePlan`, active reasons, warnings, and persistence changes. It does not import SwiftUI, AppKit, IOKit, or CoreGraphics.
- **Deep module responsibility:** `AwakeCoordinator` owns trigger combination, timer deadlines, weekly schedule evaluation, preset resolution, display-policy precedence, manual sessions, “Allow Sleep Now,” restart recovery decisions, and failure-state interpretation.
- **Platform adapters:** Keep narrow adapters behind explicit interfaces for Caps Lock state, running-app discovery, power assertions, clock/calendar, persistence, login items, notifications, and app lifecycle/wake refresh.
- **Caps Lock source:** Read `NSEvent.modifierFlags.contains(.capsLock)` as the logical state at launch and on a modest polling interval, publishing only transitions. Refresh on app activation and system wake. Do not use global key monitors or event taps, and do not request Accessibility or Input Monitoring permission. Apple documents the modifier-state property as an aggregate current state; nonstandard keyboards that do not report logical Caps Lock cannot be supported reliably.
- **Trigger combination:** Caps Lock, manual sessions, timers, schedules, and app rules are independent sources combined with OR logic. Any active source can request system-sleep prevention. Any active source that requests display-sleep prevention keeps the display awake.
- **Power policy:** Use public macOS power assertions or the equivalent `ProcessInfo` activity options. The default global policy prevents idle system sleep while allowing display sleep. A per-trigger display-awake request is stronger and wins when active. Explicit sleep, lid closure, low battery, thermal protection, and other forced sleep causes remain outside the assertion’s authority.
- **Lock-screen caveat:** A locked session remains secure, but public macOS APIs do not guarantee immediate display blackening while display sleep prevention is active. UI and documentation must not promise that locking always turns the display off.
- **Timers:** Support fixed durations, specific end times, and “until turned off.” Represent deadlines as absolute instants internally and use wall-clock time; explicit sleep does not pause a timer.
- **Schedules:** Support local-time weekly recurrence, selected weekdays, overnight ranges, daylight-saving behavior from the system calendar, and a one-off “Skip Next Occurrence” action. Do not add calendar or holiday integrations.
- **App rules:** Select installed apps through an app picker and store bundle identifiers. Each rule chooses “while running” or “while frontmost.” Multiple app rules combine with OR. A missing app disables the rule with a relink action; it is never silently replaced.
- **Presets:** Ship editable Presentation, Long Task, and Download examples. A preset stores awake mode, duration/end-time behavior, and optional end notification. Rules reference presets live; active sessions snapshot resolved preset settings at activation.
- **Manual controls:** The menu bar exposes quick presets, Custom, Until Turned Off, Allow Sleep Now, and Resume Automation. “Allow Sleep Now” releases assertions and suppresses conditions active at that moment until those conditions reset; it does not delete configuration.
- **Relaunch behavior:** Persist timed deadlines and re-evaluate Caps Lock, schedules, and app rules at launch. Restore unexpired timed sessions after unexpected relaunch. Explicit Quit cancels manual and timed sessions.
- **Persistence:** Store versioned `Codable` configuration locally in Application Support. Writes are atomic. Migrations are explicit. Corrupt data is preserved for diagnosis when possible and replaced only through a safe recovery path. JSON export/import is versioned, validated, previewable, and supports explicit merge or replace behavior.
- **UI hierarchy:** The popover presents overall status, active reasons, Allow Sleep Now/Resume Automation, quick timers and presets, automation summaries, Settings, About, and Quit in that order. Settings contains General, Presets, Schedules, and App Rules, with configuration backup and restore in General.
- **Visual language:** Use system typography, SF Symbols, template menu-bar icons, standard materials, light/dark mode, restrained transitions, and no decorative gradients, glows, custom chrome, or color-only state indicators. Support VoiceOver, keyboard navigation, focus, Dynamic Type, high contrast, and reduced motion.
- **Onboarding and defaults:** On first launch, explain behavior and privacy in one compact screen. Caps Lock is enabled as a trigger; system-sleep prevention is enabled; display sleep remains allowed; no schedules or app rules are enabled; Launch at Login and notifications are opt-in.
- **Notifications:** Do not notify for routine starts. Timer-end and assertion-failure notifications are optional and request permission only when enabled.
- **Logging:** Use structured `OSLog` categories for state transitions, adapters, persistence, and failures. Avoid personal paths and sensitive data. Never upload logs or telemetry.
- **Sandbox and distribution:** Enable App Sandbox from the beginning. Public Apple documentation states that power assertions require no special privileges, and direct Developer ID notarization and a future App Store build can share the implementation. Publish a signed/notarized ZIP with SHA-256 checksums, release notes, and a Homebrew Cask definition.
- **Open-source governance:** Use the MIT license, Semantic Versioning, GitHub Issues, and no CLA. Provide README, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, CHANGELOG, privacy statement, architecture notes, setup instructions, permission explanation, and release instructions.
- **Toolchain:** Use an Xcode macOS app with a local Swift Package for the pure core, Swift 6 strict concurrency, Swift Testing, `swift-format`, compiler warnings as errors, and the standard `xcodebuild test` workflow.
- **CI:** GitHub Actions runs formatting checks, static/compiler checks, unit tests, and a macOS build for every pull request. Signed/notarized release artifacts are produced only from version tags.

## Testing Decisions

- Tests cross the `AwakeCoordinator` interface and assert externally observable plans, active reasons, warnings, persistence changes, and commands. Tests must not inspect private implementation details or require real keyboard/power state.
- The core test suite covers Caps Lock transitions, OR combination, display-policy precedence, overlapping reasons, timers, absolute deadlines, schedules across midnight and daylight-saving transitions, preset live references, active-session snapshots, “Allow Sleep Now,” relaunch recovery, corrupt configuration, import merge/replace, missing apps, assertion failures, and notification preferences.
- Adapter tests cover the AppKit modifier-state source, running-app discovery, power-assertion lifecycle, login-item control, local persistence, notification requests, activation refresh, and wake refresh on macOS.
- Integration smoke tests run on macOS CI against the real modifier-state and power APIs where the runner permits. They verify assertion creation/release and do not claim to simulate lid closure, low-battery sleep, or thermal protection.
- UI tests verify menu-bar status, active-reason rendering, quick actions, Settings navigation, onboarding, focus order, VoiceOver labels, light/dark appearance, high contrast, Dynamic Type, and reduced-motion behavior.
- Persistence tests verify atomic writes, schema migrations, backup preservation, invalid import rejection, newer-schema rejection, merge behavior, replace behavior, and recovery after an interrupted write.
- Release checks verify Universal architecture, minimum macOS deployment target, signed/notarized artifact validity, checksum generation, ZIP contents, release notes, and Homebrew Cask metadata.
- The workspace has no existing codebase or test prior art. The first implementation must establish the core test harness and adapter test conventions as part of the initial build.

## Out of Scope

- Windows, Linux, iPadOS, or iOS support.
- Mac App Store distribution in the first release, although the architecture remains sandbox-compatible with a future App Store build.
- Accessibility or Input Monitoring permissions, global key event interception, event taps, or per-device keyboard LED control.
- Custom handling for keyboards that do not report logical Caps Lock to macOS.
- Calendar, holiday, cloud, iCloud, account, remote-control, or multi-device synchronization.
- Analytics, telemetry, crash uploads, advertising, or required network connectivity.
- Global keyboard shortcuts beyond the physical Caps Lock trigger.
- Compound AND app-rule groups, calendar exceptions beyond Skip Next, holiday databases, and cloud schedules.
- Battery-based automatic timeouts or silent changes to the user’s selected awake policy.
- Undocumented screen-lock notifications or private APIs used to force display behavior.
- A custom installer, background service, kernel extension, privileged helper, or login daemon.
- Routine start notifications, mandatory notification permission, or a Dock application window.
- Non-English shipped translations in the first release, although the string system must be localization-ready.

## Further Notes

- The display-sleep decision is intentionally explicit: system-sleep prevention is the default, while display-sleep prevention is opt-in per trigger. This preserves the core “keep work running” behavior without promising that a locked screen immediately goes black.
- The power assertion API is not a guarantee against every sleep cause. CapsAwake must represent the requested plan and the assertion result honestly, while macOS remains authoritative for explicit or safety-driven sleep.
- The `AwakeCoordinator` is the single high-level seam. Platform adapters can change independently, and tests can use fakes without reproducing AppKit or IOKit state.
- A future repository should publish this spec as a GitHub issue with the `ready-for-agent` label. This projectless workspace has no issue tracker configured, so this file is the current source of truth.
- Before public naming, check CapsAwake repository availability, bundle-identifier ownership, trademark conflicts, Apple Developer signing identity, and Homebrew Cask naming.
