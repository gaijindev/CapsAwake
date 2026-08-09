# CapsAwake architecture

CapsAwake keeps policy decisions in a small, framework-free core so the high-risk behavior can be tested without a running menu bar or power state.

## Core seam

`AwakeCoordinator` accepts `TriggerFacts` and a `CoordinatorState`, then returns an `AwakePlan`. It owns trigger combination, display-policy precedence, timer expiration, schedule evaluation, preset resolution, and the Allow Sleep Now state transition.

The core target (`CapsAwakeCore`) imports Foundation only. `AwakePlan` is the contract between policy and adapters: it contains whether idle system sleep or display sleep should be prevented, active human-readable reasons, warnings, and the next deadline.

## Platform adapters

- `CapsLockMonitor` polls `NSEvent.modifierFlags` and refreshes on app activation and wake.
- `RunningAppsMonitor` reads running and frontmost bundle identifiers from `NSWorkspace`.
- `PowerAssertionController` owns public IOKit power assertions and releases them when the plan is inactive or the app terminates.
- `LoginItemController` wraps `SMAppService`.
- `ConfigurationStore` performs versioned, atomic local persistence and validated JSON portability.

The SwiftUI layer observes `AppModel`, which builds facts, evaluates the coordinator, applies the plan, and renders status/reasons. UI code does not decide whether a trigger is active.

## State and safety

Triggers combine with OR semantics. A display-awake request is stronger than a system-only request. Assertions cover idle sleep only; explicit sleep, lid close, low battery, and thermal protection remain macOS decisions. Lock Screen security is never bypassed.
