# Release

CapsAwake releases are Semantic Versioning tags in the form `vMAJOR.MINOR.PATCH`.

The release workflow always builds a Universal macOS app and creates a ZIP plus SHA-256 checksum. When the signing and notarization secrets are configured, it additionally signs with the hardened runtime, submits to Apple's notary service, staples the ticket, and publishes the notarized ZIP.

Configure these repository secrets for a signed release:

- `APPLE_SIGNING_IDENTITY`
- `APPLE_ID`
- `APPLE_TEAM_ID`
- `APPLE_APP_PASSWORD`

Without those secrets, the workflow still creates an unsigned artifact for maintainers to inspect; it does not claim that artifact is trusted for end users. Homebrew Cask metadata lives in `Casks/capsawake.rb`. Update its version and checksum as part of the release submission.
