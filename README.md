# CapsKeep

Keep your Mac awake when Caps Lock is on.

CapsKeep is a native macOS menu-bar utility designed to make awake behavior immediate, visible, private, and predictable. Caps Lock is one trigger; timers, weekly schedules, app-based rules, and reusable presets are planned as independent triggers.

## Project status

CapsKeep is in the product-definition phase. The current source of truth is the [product specification](docs/capskeep-spec.md). Implementation has not started yet.

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

See [CONTRIBUTING.md](CONTRIBUTING.md) for the planned development workflow. Before implementation begins, read the [product specification](docs/capskeep-spec.md).

## License

CapsKeep is released under the MIT License. See [LICENSE](LICENSE).
