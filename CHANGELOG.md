# Changelog

All notable changes to this project are documented here, newest first.

## [Unreleased]

### Added
- **Combat log**: `CombatSession.log` ([LogEntry]), appended on turn changes,
  damage/heal/max-HP-increase, deaths, and combatant add/remove. New "Log"
  button in the bottom bar (center, between Previous/Next Turn) opens a
  read-only `LogView`. `Previous Turn` now truncates the log back to its
  state before the turn being undone — the existing turn-revert history
  snapshot also stores the log length at that point. Persisted with the
  session (`SessionRecord.log`, optional for old-save compatibility)

### Changed
- **Add Combatant moved to a top-right toolbar button**; the bottom-of-list
  placeholder row is gone. Discussed placement/log design with the user before
  building rather than guessing
- Round counter removed from the toolbar (was squeezed out by the Add button
  anyway) — the centered plain-text display above the list remains the only
  round indicator
- Confirmed Previous/Next Turn's Liquid Glass qualifies per Apple's own
  examples (media transport controls, which don't navigate either, are
  explicitly called out as appropriate) — bar now also carries the Log button
  with the same glass treatment (`.glass`, non-prominent)

### Added
- **Increase Max HP**: `CombatSession.increaseMaxHP(for:amount:)` raises both
  max and current HP together (a buff/level-up, not just a higher ceiling) —
  new third button on the combatant detail screen reusing the existing amount
  field alongside Damage/Heal
- Four more starter creatures: Ogre, Giant Spider, Giant Rat, Cultist —
  fills out brute/ambusher/swarm-filler/caster roles the existing seven didn't
  cover, HP + initiative bonus researched for realism

### Fixed
- **Main menu "Resume" could show stale, wrong state** (e.g. still red/enabled
  right after deleting the session it pointed at). Root cause: `canResume` was
  a computed property calling `SessionStore.resumableSession()`, which reads
  UserDefaults/disk — state `@Observable` doesn't track. `MainMenuView` is also
  the `NavigationStack`'s persistent root, so popping back to it doesn't force
  a re-render on its own; the button kept showing whatever it last rendered.
  Fixed by making it a real `@State` var refreshed in `.onAppear`. Documented
  the general pattern in the `ios-hig` skill.
- Damage/heal amount field on the combatant detail screen was cramped next to
  the Damage/Heal buttons on narrow widths — amount field now gets its own
  full-width row, buttons on the row below

### Changed
- Renamed the "Combatants" preset-management menu entry/screen to **Creatures**
  — it manages reusable creature templates, not the actual combatants in a
  session, and shared the same word as the real thing was confusing. Icon
  changed from `person.3.fill` (implies literal humans) to `pawprint.fill`
  (reads as "creature" generically — goblins, skeletons, wolves, whatever)
- Creature presets now also carry an **Initiative Bonus** (flat modifier added
  to random 1–20 rolls only, never on top of an explicit value) — edited from
  Main Menu → Creatures, applied silently when adding a combatant whose name
  matches a preset. `CombatSession.addCombatant`/`addCombatants` both take an
  `initiativeBonus: Int = 0` parameter now
- Four more generic starter creatures: Orc, Wolf, Zombie, Guard (alongside the
  existing Goblin/Skeleton/Thief), each with HP + initiative bonus researched
  for realism, described only in our own generic terms
- Load Session: removed the extra confirmation dialog on delete — swipe-to-
  reveal + tap Delete is already two deliberate actions

### Added
- **HP tracking**: opt-in per combatant (`maxHP`/`currentHP` on `Combatant`),
  damage/heal controls and a "Track HP" prompt on the detail screen, HP shown
  in the list row colored by remaining fraction, and a "Dead" badge/skull icon
  + dimmed row when HP hits 0 (combatant stays in turn order, not auto-removed)
- **Round counter**: `CombatSession.roundNumber`, increments when turn order
  wraps to the first combatant, reverts correctly via Previous Turn, shown both
  in the toolbar and as plain centered text above the combatant list
- **Editable session name**: the combat screen's title is now a text field
  bound to `session.name`; blank input is ignored. Default name shortened to a
  short-form date (was overflowing the toolbar and squeezing out the round
  counter)
- **Remove combatant**: swipe left + confirm, matching the pattern already used
  for sessions; adjusts `currentTurnIndex` correctly and clears turn-revert
  history (a reverted-to snapshot could otherwise resurrect a removed combatant)
- **Add-combatant modal**: replaced the inline card row (too easy to trigger by
  an accidental tap outside it, and too fiddly to hit the small per-field
  controls) with a plain "Add Combatant" tap target at the *bottom* of the list
  that opens a native `Form` sheet — full-size rows for Name/Initiative/Max
  HP/Count
- **Creature presets**: adding a combatant auto-saves/updates a `CreaturePreset`
  by name (`PresetStore`, no explicit save step) — typing a name that matches
  an existing preset auto-fills its HP. Three generic starter presets ship on
  first launch. Managed from a new Main Menu "Creatures" entry: edit name/HP,
  swipe to delete with confirmation
- Previous/Next Turn bar now uses Liquid Glass on iOS 26+ (`GlassEffectContainer`,
  `.glassProminent` for Next Turn, `.glass` for Previous Turn), gated with
  `#available(iOS 26.0, *)` and falling back to the existing themed bar below
  that. It's the only glass button in the app — went through every button and
  only this one qualifies as a floating control per Apple's guidance ("reserved
  for the navigation layer that floats above content"); documented the full
  reasoning in the `ios-hig` skill so future buttons get evaluated the same way

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
