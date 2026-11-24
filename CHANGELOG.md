# Changelog

All notable changes to Clipd are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Intel Mac builds (`Clipd-intel.app.zip`), released separately on `intel-v*`
  tags so they can lag behind Apple Silicon without holding up a release.

### Changed

- Releases are built and published by GitHub Actions. The tag shape picks the
  architecture: `v*` builds Apple Silicon and takes the Latest slot,
  `intel-v*` builds Intel and never does. A `-rc.N` suffix on either publishes
  as a prerelease.

## [1.1.0] - 2026-11-18

### Added

- Global shortcut: ⌥⌘V opens Clipd from anywhere; ↑/↓ to pick, Return to copy
  and jump back to the previous app, Esc to dismiss. Can be turned off in settings.
- Ignored apps: nothing copied while a chosen app is in front is recorded.
- Launch at login, toggled from settings.
- Configurable history size: 10, 30 (default), 50, 100 or 200 unpinned items.
- Privacy policy (PRIVACY.md), linked from the settings menu, and an Apple
  privacy manifest in the app bundle.

### Changed

- Clipd now runs in the macOS App Sandbox: no file access outside its own
  container and no network access.
- History and settings now live in `~/Library/Containers/com.folade.clipd/`.
  On first launch macOS moves existing 1.0.x history and settings there. The
  move is one-way and only happens when the container is first created; if
  history is missing, look in `~/Library/Application Support/Clipd/`.

## [1.0.1] - 2026-09-10

### Fixed

- The Theme picker now applies Light/Dark to the menu bar popover (the
  preference is applied process-wide instead of on the `Scene`).
- The downloaded app's code signature is no longer broken: xattrs are stripped
  before signing, the zip is made with `ditto --sequesterRsrc`, and the
  signature is verified from the extracted archive.

### Changed

- Clip rows no longer show a relative timestamp.

## [1.0.0] - 2026-08-18

### Added

- First release: history of the last 30 copied text snippets (pinned items
  exempt from the cap), menu bar popover plus optional Dock window, search,
  pin, pause recording, clear history, dark and light themes or follow the
  system. No networking, no analytics, no special permissions.

[Unreleased]: https://github.com/net-folade/clipd/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/net-folade/clipd/compare/v1.0.1...v1.1.0
[1.0.1]: https://github.com/net-folade/clipd/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/net-folade/clipd/releases/tag/v1.0.0
