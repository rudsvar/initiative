# Changelog

All notable changes to this project are documented here, newest first.

## [Unreleased]

### Changed
- Main menu "Resume" button is now hidden entirely (not just disabled) when
  there's no session to resume, instead of showing a muted-but-still-visible
  button that did nothing when tapped
- Confirmed and documented: the app requests zero permissions (no usage-
  description keys, no entitlements, all storage local) and is already a
  universal build (`UIDeviceFamily` includes tablet) — see `SPEC.md`
- Renamed `Participant` → `Combatant` throughout the codebase (types, files, UI
  copy, docs) — confirmed with user; `ParticipantDetailView.swift` is now
  `CombatantDetailView.swift`
- Combatant name and initiative are now editable from the detail screen (bordered
  text fields bound directly to the session, matching the add-row style); the
  list re-sorts automatically since sort order is always computed fresh

### Planned
- HP tracking (opt-in per combatant) + a clear "dead" indicator when HP hits 0 —
  design written up in `SPEC.md` §5 ("HP Tracking"); not yet implemented, awaiting
  confirmation on the design before building

### Fixed
- Main menu "Resume" button could appear enabled (bold red, primary styling) while
  actually disabled, and would silently no-op if tapped in that state — this could
  happen if the tracked "last active session" pointer went stale (its file missing/
  unreadable). Fixed two ways: `SessionStore.resumableSession()` now self-heals by
  clearing the stale pointer the moment it can't load the record, and the Resume
  button only uses the bold "primary" styling when it's actually enabled (falls back
  to the same muted look as New Session/Load Session otherwise) so a disabled state
  can't be visually mistaken for a live one
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
- `Combatant`/`Effect`/`DurationType` are now `Codable` (`DurationType` has a
  hand-written implementation since its associated-value cases can't synthesize)
- "Menu" button (top-left) on the combat screen; autosaves on leaving the screen or
  app backgrounding
- New `ios-hig` skill (`<agent-config>/skills/ios-hig/SKILL.md`)
- `SessionStoreTests` and new `CombatSession` reset/record tests (35 tests total)

### Fixed
- `DEVELOPMENT_TEAM` in `project.yml` was blank, so every `xcodegen generate`
  silently stripped code signing and broke device builds — set to the correct
  personal team ID (`YOUR_TEAM_ID`, verified against Xcode's own account records)
- `CombatantDetailView` was reachable via `NavigationLink` from a `ContentView`
  that had no `NavigationStack` ancestor of its own — fixed as part of introducing
  `RootView`'s app-wide stack

### Changed
- UI pass against Apple's Human Interface Guidelines (new `ios-hig` skill at
  `<agent-config>/skills/ios-hig/SKILL.md`): name/initiative are now separate bordered
  text boxes instead of borderless text floating in one row; add button moved
  fully outside the initiative box with clear spacing; bottom bar relabeled
  "Previous Turn"/"Next Turn" with chevrons on the correct (outer) sides
- Replaced the "Add Combatant" modal with an always-visible inline row pinned
  atop the combatant list — name + initiative fields, add via return key or the
  plus button; random 1–20 initiative still applies when left blank
- "Back" now reverts to the previous turn's full state (turn index, reactions,
  effects) via a session history stack, instead of just calling `nextTurn()` again
- Extracted all inline `Color(red:green:blue:)` literals into `Theme.swift`; bumped
  the accent color from muted rust to a more saturated red per feedback

### Added
- `CombatSession.previousTurn()` / `canGoToPreviousTurn`, backed by a snapshot
  history pushed on each `nextTurn()`
- `Theme.swift` — single source of truth for the old-paper color palette
- Combatant detail view, reaction toggle, and custom effect management
  (add/remove, all four duration types, target picker)
- `initiativeTests` XCTest target covering turn advancement, reaction reset,
  effect expiration, and turn-revert logic (23 tests)
- Initial SwiftUI iOS app scaffold with Xcode 15+ support
- XcodeGen project configuration for reproducible builds
- Starter ContentView with SwiftUI Preview
- Bundle ID: xyz.rudsvar.initiative, iOS 17+ deployment target
- Development documentation (CLAUDE.md, README.md)
