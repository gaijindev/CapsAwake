# Contributing to CapsKeep

CapsKeep is currently in the product-definition phase. Read the [product specification](docs/capskeep-spec.md) before opening an implementation pull request.

## Development expectations

- Keep policy decisions inside the pure `AwakeCoordinator` module.
- Keep macOS behavior behind narrow adapters.
- Add external-behavior tests for every new policy path.
- Preserve the privacy boundary: no accounts, telemetry, analytics, or required network access.
- Use the native macOS visual language and accessibility conventions.

The project will document the exact Xcode, formatting, test, and release commands when the first implementation lands.

## Pull requests

Explain the user-facing behavior, the policy decision being changed, and the tests that prove it. Keep pull requests focused and update the specification when a decision changes.
