# Changelog

All notable changes to this project are documented here, newest first.

## [Unreleased]

### Fixed
- **App ran letterboxed (black bars top/bottom) on real devices.** Root cause:
  `GENERATE_INFOPLIST_FILE: YES` makes Xcode build Info.plist purely from
  `INFOPLIST_KEY_*` build settings — the target's `infoPlist:` dict in `project.yml`
  (launch screen, scene manifest, orientations) was silently ignored and never reached
  the built app, so iOS fell back to legacy letterboxed scaling. Replaced with
  `INFOPLIST_KEY_UILaunchScreen_Generation`/`INFOPLIST_KEY_UIApplicationSceneManifest_Generation`/
  `INFOPLIST_KEY_UISupportedInterfaceOrientations`, verified present in the built
  `.app`'s actual Info.plist this time (`plutil -p`), not just trusted from `project.yml`
- `AddEffectView` had overlapping content on smaller screens / with the target picker
  expanded — rewritten from a hand-rolled `VStack` to a native `Form`/`Section` layout,
  which scrolls and handles safe areas on its own

### Changed
- No more explicit "Save Session" step: every `CombatSession` now has a stable auto-
  generated identity (`id` + date-based `name`); autosave just overwrites that session's
  file, so it's discoverable under "Load Session" without a save button/name prompt
- "Load Session": swipe-to-delete now requires confirmation before deleting, and the
  empty state uses the native `ContentUnavailableView`
- Direction: new/reworked screens should prefer native iOS components (`Form`, `List`,
  system tint) over the custom `Theme` styling, for now — see `CLAUDE.md`

### Added
- Main menu (Resume / New Session / Load Session) as the app's launch screen,
  wired through a shared `NavigationStack` (`RootView.swift`)
- Session persistence: `SessionStore` (JSON-on-disk, one file per session, keyed by
  the session's stable id), `SessionRecord`, `CombatSession.reset()/makeRecord()/load()`
- `Participant`/`Effect`/`DurationType` are now `Codable` (`DurationType` has a
  hand-written implementation since its associated-value cases can't synthesize)
- "Menu" button (top-left) on the combat screen; autosaves on leaving the screen or
  app backgrounding
- New `ios-hig` skill (`<agent-config>/skills/ios-hig/SKILL.md`)
- `SessionStoreTests` and new `CombatSession` reset/record tests (35 tests total)

### Fixed
- `DEVELOPMENT_TEAM` in `project.yml` was blank, so every `xcodegen generate`
  silently stripped code signing and broke device builds — set to the correct
  personal team ID (`YOUR_TEAM_ID`, verified against Xcode's own account records)
- `ParticipantDetailView` was reachable via `NavigationLink` from a `ContentView`
  that had no `NavigationStack` ancestor of its own — fixed as part of introducing
  `RootView`'s app-wide stack

### Changed
- UI pass against Apple's Human Interface Guidelines (new `ios-hig` skill at
  `<agent-config>/skills/ios-hig/SKILL.md`): name/initiative are now separate bordered
  text boxes instead of borderless text floating in one row; add button moved
  fully outside the initiative box with clear spacing; bottom bar relabeled
  "Previous Turn"/"Next Turn" with chevrons on the correct (outer) sides
- Replaced the "Add Participant" modal with an always-visible inline row pinned
  atop the participant list — name + initiative fields, add via return key or the
  plus button; random 1–20 initiative still applies when left blank
- "Back" now reverts to the previous turn's full state (turn index, reactions,
  effects) via a session history stack, instead of just calling `nextTurn()` again
- Extracted all inline `Color(red:green:blue:)` literals into `Theme.swift`; bumped
  the accent color from muted rust to a more saturated red per feedback

### Added
- `CombatSession.previousTurn()` / `canGoToPreviousTurn`, backed by a snapshot
  history pushed on each `nextTurn()`
- `Theme.swift` — single source of truth for the old-paper color palette
- Participant detail view, reaction toggle, and custom effect management
  (add/remove, all four duration types, target picker)
- `initiativeTests` XCTest target covering turn advancement, reaction reset,
  effect expiration, and turn-revert logic (23 tests)
- Initial SwiftUI iOS app scaffold with Xcode 15+ support
- XcodeGen project configuration for reproducible builds
- Starter ContentView with SwiftUI Preview
- Bundle ID: xyz.rudsvar.initiative, iOS 17+ deployment target
- Development documentation (CLAUDE.md, README.md)
