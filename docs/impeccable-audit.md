# Impeccable audit

Date: 2026-08-09

Scope: CapsAwake native macOS UI and repository guides

## Scope clarification

CapsAwake is a native SwiftUI menu-bar application. The repository has no HTML,
CSS, JavaScript, or responsive website surface. “Web and mobile view” is
therefore not an applicable product target for this codebase. The native
surfaces are the menu-bar popover, Settings window, onboarding sheet, and About
dialog.

## Checks run

- `npx impeccable check` — Impeccable v4.0.4 is current.
- `npx impeccable detect Sources README.md docs --json --viewport 1280x800` — no local detector findings.
- `npx impeccable detect Sources README.md docs --json --viewport 390x844` — no local detector findings.
- `markdown-link-check` across all repository guides — no broken links reported.
- `markdownlint-cli2` — one fenced-code-language issue was fixed in
  `docs/agents/domain.md`; remaining MD013 line-length findings are source
  wrapping preferences and do not change GitHub’s responsive paragraph layout.

The Impeccable detector was also pointed at the GitHub repository page at
desktop and mobile widths. Its findings were GitHub’s own navigation and
animation chrome, not files controlled by CapsAwake, so they were not treated
as product defects.

## Native surface review

| Dimension | Result | Notes |
| --- | --- | --- |
| Accessibility | Good | Key states, actions, warnings, and destructive controls have labels; an interactive VoiceOver pass remains a signed desktop validation step. |
| Performance | Excellent | Lightweight SwiftUI views, a one-second state refresh, and no image or network pipeline. |
| Appearance | Excellent | System typography, semantic colors, SF Symbols, native materials, and dark-mode support. |
| Platform conformance | Excellent | MenuBarExtra, Settings, AppKit power assertions, and no web-shaped navigation. |
| Adaptivity | Good for macOS | Native windows use bounded sizes; iOS/Android/mobile-web support is intentionally out of scope. |

## Follow-up boundary

If a responsive website or hosted documentation site is desired, it needs to be
created as a separate surface first. Once that surface exists, Impeccable can
run a real desktop/mobile browser audit against its routes.
