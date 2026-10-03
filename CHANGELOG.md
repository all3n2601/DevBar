# Changelog

## 0.2.0-beta.3

- Replaced the detailed illustrated icon with an original, scalable phone-and-terminal vector mark.
- Updated the app icon, README, and marketing artwork to the same clean cyan/violet design with transparent corners.
- Generalized the SVG rendering script for both logo and banner assets.

## 0.2.0-beta.2

- README branding: original DevBar artwork, a custom banner, and previews rendered from the actual SwiftUI device and tools screens.
- Native multi-resolution macOS app icon included in the signed release bundle.
- Custom phone-and-terminal menu bar glyph that adapts to light and dark menu bars.
- Reproducible icon and documentation image generation; preview capture is debug-only.

## 0.2.0-beta.1

First public beta.

- Shared device operations for CLI, MCP, and the menu bar's boot, shutdown, installation, screenshot, and GPS workflows.
- Bounded subprocess execution with file-backed stdout/stderr capture to prevent pipe deadlocks.
- Readiness-based boot, real exit statuses, ambiguous-name rejection, validated GPS coordinates, and targeted MCP location control.
- CLI doctor, JSON output, installation, app launch, deep links, and location commands.
- Nine MCP tools; request validation, notification handling, clean stdio, and tool failure reporting.
- Portable configuration and screenshot paths; corrected iOS screenshot and GPS command arguments.
- Persistent favorites and device ID copying; visible GUI boot/shutdown errors; tool diagnostics and targeted app launch/deep-link controls.
- Physical Android safeguards, simulator-only iOS builds, explicit Android FCM limitation, and bounded recording stop.
- Erase confirmation; preference edits preserve unrelated keys and value types, reject path traversal, and never overwrite after a failed read.
- Regression tests, executable smoke checks, universal macOS app/CLI packaging, checksums, and GitHub CI/release workflows.

Known limitations: unnotarized app, hardware validation still required, experimental private storage editing, and Android recording duration limits. See README.

Validation: 16 regression tests, CLI/MCP executable smoke checks, universal package/signature checks, and a local iOS 26.5 simulator run covering boot, Settings app launch, deep link, GPS, PNG capture, and shutdown. Physical Android and Intel execution remain unverified. Automated GUI inspection was unavailable in the development environment.
