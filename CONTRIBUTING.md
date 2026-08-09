# Contributing to CapsAwake

Read the [product specification](docs/capsawake-spec.md) before opening an implementation pull request. The architecture is documented in [docs/architecture.md](docs/architecture.md).

## Development expectations

- Keep policy decisions inside the pure `AwakeCoordinator` module.
- Keep macOS behavior behind narrow adapters.
- Add external-behavior tests for every new policy path.
- Preserve the privacy boundary: no accounts, telemetry, analytics, or required network access.
- Use the native macOS visual language and accessibility conventions.

Run `./Scripts/check-format.sh`, `swift test`, and the Xcode test command from [docs/setup.md](docs/setup.md) before opening a pull request. Changes that affect power policy should include a focused `AwakeCoordinator` test.

## Pull requests

Explain the user-facing behavior, the policy decision being changed, and the tests that prove it. Keep pull requests focused and update the specification when a decision changes.
