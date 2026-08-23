# Changelog

All notable changes to this project are documented here, newest first.

## [Unreleased]

### Changed
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
