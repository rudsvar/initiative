# Changelog

All notable changes to this project are documented here, newest first.

## [Unreleased]

### Changed
- Damage/Heal/Increase-Max-HP controls consolidated into one row: the amount
  field plus three equal icon-only buttons (minus/plus/up-heart) next to it,
  replacing the old layout (amount field, then a two-button Damage/Heal row,
  then a separate full-width "Increase Max HP" row below) that felt like the
  actions were "placed a bit everywhere" per feedback
- Combatant list's status row reworked into wrapping chips: each active
  status (reaction used, each effect) now gets its own small darker rounded
  box with an icon + short label (e.g. "Stunned", "Used"), laid out via a
  new `FlowLayout` (`Theme.swift`) that wraps to the next line on overflow
  instead of clipping. Replaces the earlier bare-icons-in-a-row version and
  the `LetterBadge` component (removed, now unused)
- Reaction's icon changed from the custom "R" `LetterBadge` to SF Symbols
  `hand.tap.fill`/`hand.tap` — deliberately not `bolt.fill`/`bolt.slash.fill`,
  which are already used by the Paralyzed/Incapacitated standard conditions
- Combat Log now reads chronologically (oldest round/entry first, like a
  chat log) instead of newest-first, and opens scrolled to the bottom
  (most recent entry) via `ScrollViewReader` — that's almost always what
  you want to see first anyway
- Reaction-used is no longer specially called out with its own text row on
  the main combatant list — it's just another symbol (the red "R"
  `LetterBadge`) alongside the effect condition icons. And that whole status
  row now shows symbols only, no text names — full names/durations are
  reserved for the combatant detail screen
- Combatant detail screen no longer hides exact HP/AC in player view — it
  always shows editable exact numbers now, regardless of the toggle.
  Tapping into a creature is a deliberate DM action, not something a player
  glances at over their shoulder the way the main list might be, so an
  approximate mode there added friction without protecting anything. The
  player-view toggle now only affects the main combatant list

### Fixed
- Session name still wasn't centered to the true phone-screen center after
  the eye-icon toolbar fix — `.principal` centers relative to leading/
  trailing button widths, not the true center, and "Menu" (icon+text) vs
  "Add" (icon-only) are unequal widths. Moved the name back into the body
  as its own centered row (same fix already used for the bottom bar's Log
  button) instead of the toolbar

### Changed
- Main combatant list now shows HP/AC again (when set) — exact numbers in DM
  view, the same approximate bands as the detail screen in player view.
  Reverses the earlier "spoiler-free list" decision on direct instruction.
  `healthBand`/`armorClassBand` extracted to a shared `StatusBand` enum
  (`Theme.swift`) so the list and detail screen read identical bands instead
  of two copies that could drift

### Fixed
- Armor Class was hidden entirely (not shown as an approximate, just gone) in
  the combatant detail screen when player view was on — now shows a Low/
  Average/High AC band, mirroring the existing HP health band, instead of
  disappearing
- Session name field wasn't actually centered once the DM/player-view eye
  icon was added as a second trailing toolbar button — root cause was nav bar
  `.principal` centering relative to leading/trailing button widths, not the
  true screen center. Fixed by removing the eye icon from the toolbar
  entirely (see Changed below) rather than moving the name out — with only
  "Menu" and "Add" left flanking it, `.principal` centers correctly again

### Changed
- The DM/player-view eye toggle moved out of the toolbar (where it was a
  second trailing icon competing with "Add" and skewing the session-name
  centering) into a small icon in the bottom bar next to Log. There is now
  exactly one control for it, not a duplicate copy on the combatant detail
  screen's Health header — removed that one too
- Effect durations simplified: dropped "until start/end of **target's**
  next turn" entirely (effects are always self-applied to the combatant
  they're on, so a "target" concept never made sense) and added an optional
  turn count instead — durations are now "until start/end of their turn",
  repeatable across N turns via a stepper (default 1) rather than a
  one-off single-turn expiry only
- Combatant list row no longer shows "Reaction available" — only "Reaction
  used" appears, and only when true. Available is now the implied default
  (absence of the badge), matching how the effects list already only shows
  active effects rather than a placeholder for every possible one. The
  detail screen's reaction toggle is unchanged (it needs to show both states,
  since that's the actual control)

### Added
- **Armor Class**: opt-in per combatant (`Combatant.armorClass`,
  `CreaturePreset.armorClass`), editable everywhere HP already was. Confirmed
  "AC"/"Armor Class" is a generic tabletop term, not trademarked, before adding
- **Standard status conditions** (`Conditions.swift`): Blinded, Charmed,
  Deafened, Frightened, Grappled, Incapacitated, Invisible, Paralyzed,
  Poisoned, Prone, Restrained, Stunned, Unconscious, Exhausted, Burning,
  Bleeding — each with an SF Symbol icon + color, quick-picked from a new
  "Choose Condition" menu in Add Effect. Effect badges (list row + detail
  screen) now show the matched icon/color instead of a generic sparkle.
  Confirmed condition names aren't trademarked/copyrighted (single descriptive
  words like "stunned" aren't ownable) and SF Symbols are licensed for in-app
  UI use before building this
- **DM/Player view toggle**: HP is no longer shown on the main combatant list
  at all (regardless of the toggle) — just name/initiative/reaction/effects.
  The detail screen's eye icon (also mirrored in the toolbar) switches between
  exact DM view (editable HP/AC, damage/heal controls) and player view (a
  single approximate health band — Healthy/Wounded/Critical/Dead, deliberately
  generic wording — with AC hidden entirely). `CombatSession.playerViewEnabled`
  is a live UI mode, not persisted
- **Encounters**: prepare a named creature list ahead of time (Main Menu →
  Encounters), then start a session already populated with it via a new
  "Fresh Session" vs. saved-encounter chooser on "New Session". Entries are
  stat snapshots, not live preset references, so editing/deleting a preset
  later doesn't retroactively change an existing encounter. Initiative is
  always rolled fresh per combatant at session start, never stored in the
  encounter
- Creatures screen: can now create a new preset directly (top-right "+"), not
  just edit ones that originated from adding a combatant in a session
- Session title field now selects all its text on focus (`SelectAllTextField`,
  a small `UITextField` bridge — plain SwiftUI `TextField` has no pre-iOS-18
  way to do this) so renaming doesn't require manually clearing the old value
- Explicitly excluded per direct instruction: legendary/lair actions, held/
  delayed turns, private per-combatant notes

### Fixed
- Main menu button icons had different intrinsic widths (play vs. pawprint vs.
  shield glyphs), so button text started at a different x-offset per button —
  fixed with a fixed-width icon frame so all button labels align
- Previous/Next Turn buttons shortened to "Previous"/"Next" (dropped the
  redundant "Turn" — implied by context) and toolbar "Add" became a plus icon,
  matching standard iOS conventions

### Changed
- **Reaction tracking reimplemented internally as a regular effect.** Using a
  reaction now appends an `Effect(.untilStartOfTheirTurn, isReactionMarker: true)`
  to the combatant instead of setting a separately-stored bool — it expires
  through the same `removeExpiredEffects` pass every other effect already uses,
  so `nextTurn()` no longer needs its own bespoke reaction-reset line.
  `Combatant.reactionUsed` is now computed (`effects.contains { isReactionMarker
  == true }`); `useReaction`/`resetReaction`/`toggleReaction` on `CombatSession`
  replace direct bool mutation. New `Combatant.visibleEffects` filters the
  marker out of the user-facing effects list (it has its own dedicated Reaction
  UI). No user-visible behavior change — purely an internal simplification
- Reaction indicator replaced the SF Symbol checkmark/xmark with a custom red
  "R" badge (`Theme.LetterBadge` — a `Circle` + `Text`, no image asset
  needed): filled red when available, outlined/muted when used. Used both on
  the combatant list row and the detail screen's reaction toggle for
  consistency

### Fixed
- Reaction status ("Reaction available"/"Reaction used") on combatant list
  rows wasn't horizontally aligned between combatants — it was appended after
  Init/HP on the same line, so its position shifted depending on whether a
  given combatant had HP tracked. Moved to its own row, always leading-aligned

### Added
- **Log entries are now editable, scoped to HP.** Damage/healing/max-HP-increase/
  HP-tracking-started entries carry structured data (`HPOperation` enum + target
  combatant id) behind the display text; swiping one away recomputes that
  combatant's current/max HP from the remaining entries via
  `CombatSession.deleteLogEntry`/`recomputeHP`. Turn changes, add/remove, and
  deaths stay non-deletable for now — undoing those safely means touching
  derived turn order, which is a bigger, riskier change than fixing an HP
  typo; discussed the scope with the user before building rather than
  guessing at it
- Log view now groups entries into sections by round number, newest round first
- Add-combatant modal: "Choose Creature" menu listing saved presets by name
- Removed the extra delete-confirmation dialog for creature presets — swipe +
  tap Delete is already two deliberate actions, matching sessions/combatants

### Changed
- Add-combatant modal field order: Name, Max HP, Count, Initiative (Initiative
  moved last since it's the field most often left blank)
- `addCombatants` no longer forces independent random rolls when count > 1 and
  an explicit initiative is given — every spawned copy now gets that same
  value, matching what you'd expect from typing a number. Still rolls
  independently per copy when initiative is left blank

### Fixed
- Real bug found while building the above: combatants created with Max HP set
  *at add time* (vs. later via "Track HP") had no `.enableTracking` log entry,
  so deleting an unrelated HP entry for them would recompute to nil HP,
  wiping them. Both `addCombatant` and `addCombatants` now log that baseline
  entry whenever `maxHP` is provided at creation
- Bottom bar's Log button wasn't actually centered — the two-`Spacer()` layout
  only balances the gaps around it, not the true bar center, when the side
  buttons ("Previous Turn" vs "Next Turn") have unequal widths. Fixed with
  three equal-width flexible columns instead

### Added
- Add-combatant modal now has a "Choose Creature" menu listing saved presets
  by name — picking one fills Name + Max HP directly (an explicit full
  overwrite, unlike the passive typing-based auto-fill which only fills HP if
  still empty)
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
