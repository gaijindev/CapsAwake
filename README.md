# CapsAwake

Keep your Mac awake when Caps Lock is on.

CapsAwake is a native macOS menu-bar utility designed to make awake behavior immediate, visible, private, and predictable. Caps Lock is one trigger; timers, weekly schedules, app-based rules, and reusable presets are independent triggers.

## Project status

The first implementation is in place: the pure policy core, menu-bar app shell, Caps Lock polling, public power assertions, timers, presets, schedules, app rules, local persistence, onboarding, and release automation are all included. The [product specification](docs/capsawake-spec.md) remains the source of truth for behavior.

## Run locally

```sh
swift test
./Scripts/check-format.sh
xcodegen generate
xcodebuild -project CapsAwake.xcodeproj -scheme CapsAwake \
  -destination 'platform=macOS' test CODE_SIGNING_ALLOWED=NO
```

Open `CapsAwake.xcodeproj` in Xcode to run the menu-bar app. See [setup](docs/setup.md), [architecture](docs/architecture.md), [release](docs/release.md), and the [Impeccable audit](docs/impeccable-audit.md) for details.

## Product principles

- Native macOS behavior and visual language.
- No accounts, analytics, telemetry, or required network access.
- No Accessibility or Input Monitoring permission for Caps Lock state.
- Explicit status and active-reason reporting.
- A small, testable policy core behind platform adapters.
- Open development with reproducible checks and signed releases.

## Planned support

- macOS 14 or newer.
- Universal binary for Apple silicon and supported Intel Macs.
- Signed and notarized GitHub releases, followed by a Homebrew Cask.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the development workflow. Before changing behavior, read the [product specification](docs/capsawake-spec.md).

## License

CapsAwake is released under the MIT License. See [LICENSE](LICENSE).
