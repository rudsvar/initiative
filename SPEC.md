# Project Specification

## Overview

**initiative** is a personal iOS application. The scope and feature roadmap are defined here.

## Target Platform & Requirements

- **Platform**: iOS 17+
- **Device**: phone (primary), tablet also supported — the build is universal
  (`UIDeviceFamily` includes both; no `TARGETED_DEVICE_FAMILY` restriction in
  `project.yml`) and layouts use adaptive containers (`List`, `Form`,
  `GeometryReader`-based centering), but tablet-specific layout (split view,
  larger-screen affordances) hasn't been deliberately designed for — it just
  runs, unverified for tablet-optimized UX
- **Permissions**: none. No `NS*UsageDescription` keys, no entitlements, no
  camera/location/photos/network access — verified by inspecting the built
  `Info.plist`. All storage is local (`SessionStore`'s JSON files + UserDefaults),
  no network calls anywhere in the app
- **Development Environment**: Xcode 15+
- **App Type**: Native SwiftUI single-window application
- **Bundle ID**: xyz.rudsvar.initiative

## Core Goals

Build a clean, minimal initiative tracker for managing turn order and temporary effects in tabletop combat. The app maintains combatant order, tracks reactions, and manages duration-based effects across multiple turn types.

## Feature Roadmap

### Phase 0: Foundation (Current)
- ✅ Project scaffold with SwiftUI & XcodeGen
- ✅ Runnable starter app on phone
- ⏳ MVP feature implementation

### Phase 1: MVP (Combat Tracking)
- ✅ List view of combatants sorted by initiative (descending)
- ✅ Add combatant with custom or random (1–20) initiative
- ✅ Next Turn button to advance turn order
- ✅ Reaction tracking per combatant (reset on their turn)
- ✅ Temporary effects with multiple duration types
- ✅ Effect target selection
- ✅ Back button to return to prior state (undo stack of full session snapshots)

### Phase 2: Polish
- ✅ Combat session persistence (save/load) + main menu (Resume / New / Load)
- ✅ Remove combatant (swipe left + confirm)
- ✅ Round counter display
- Visual indicators for effects and reaction state
- Haptic feedback on turn advance

### Phase 3: HP Tracking
- ✅ Per-combatant current/max HP, opt-in (not every combatant needs it tracked)
- ✅ Quick damage/heal adjustment
- ✅ Clear "dead" indicator when HP reaches 0

### Phase 4: Preset Creatures
- ✅ Every combatant added auto-saves as a reusable preset by name — no explicit
  "save as preset" step
- ✅ A built-in default roster to start from, installed additively so later
  versions' additions reach existing installs (see Default Content)
- ✅ Presets are viewed/edited/deleted from Main Menu → Creatures, not from the
  add-combatant flow

### Phase 5: DM-side Prep & Play Tools
- ✅ Armor Class, opt-in per combatant (like HP)
- ✅ Standard status conditions (stunned, paralyzed, poisoned, etc.) with SF
  Symbol icons + colors, quick-picked in the Add Effect flow
- ✅ DM/player view toggle: HP is never shown on the main combatant list; the
  detail screen defaults to exact numbers (DM view) and can be toggled to
  approximate health bands + hidden AC (player view) via an eye icon
- ✅ Pre-made named Encounters: prepare a creature list ahead of time, start a
  session already populated with it from the Main Menu's "New Session" chooser
- Explicitly excluded (per direct instruction): legendary/lair actions, held/
  delayed turns, private per-combatant notes

## Core Features

### 1. Combatant Management

**Add Combatant**
- Top-right toolbar button ("Add") opens a modal (native `Form`) with fields
  in this order: Name, Max HP, Count, Initiative (Initiative last — it's the
  field most often left blank, so it doesn't need to interrupt the fields
  that are usually filled in). Each is a full-size Form row (not small inline
  boxes) so they're easy to hit precisely. This is the sole entry point —
  earlier designs (an inline row atop the list, then a bottom placeholder
  row) both turned out to want a dedicated modal in the end (fiddly small
  fields, or risk of an accidental tap), so the toolbar button replaced the
  placeholder row entirely rather than adding a second one
- Leaving initiative blank rolls random 1–20 on add
- Count > 1 spawns that many copies with numbered names ("Goblin 1", "Goblin 2",
  ...). If initiative is left blank, each copy rolls independently; if an
  explicit initiative is given, **every copy gets that same value** — no
  special-casing, what you typed is what they get
- A "Choose Creature" menu (shown only when at least one preset exists) lists
  saved presets by name — picking one fills Name + Max HP directly (overwrites
  HP, unlike the passive typing-based match below, since this is an explicit choice)
- Adding a combatant auto-saves/updates a `CreaturePreset` by name (see §8) —
  no separate save step; typing a name that matches an existing preset
  auto-fills its saved HP into the HP field if HP is still empty
- Combatants auto-sort by initiative (descending; ties maintain insertion order)

**Combatant Display**
- Row layout uses the full row width: **initiative** is a large far-left
  column in tabular figures (it's the value the list is sorted by, so it reads
  as the primary at-a-glance number; monospaced digits keep the column from
  shifting between one- and two-digit values). Only the *current* combatant's
  number is accent-colored — the rest are `textSecondary`, since gold is
  reserved for marking one thing per screen. **Name** sits next to it in the
  app's serif face; **HP/AC** (when set) is a right-aligned, icon-led column — a heart icon for HP, a shield
  icon for AC, left-aligned within that column so the icons themselves line
  up regardless of digit count (exact numbers in DM view, approximate bands
  in player view, see §12)
- No arrow/chevron icon marks the current-turn row — the row's own surface
  lift + accent outline + accent leading edge bar (see below) is the sole
  indicator
- A wrapping row of small chips shows active statuses (reaction used +
  active effects) below the name/HP row — each status gets its own darker
  rounded box (`StatusChip`, `ContentView.swift`) with an icon plus a short
  label (e.g. "Stunned", "Reaction"), laid out via a custom `FlowLayout`
  (`FlowLayout.swift`, SwiftUI `Layout` protocol) so several sit side by side and
  wrap to the next line on overflow. `FlowLayout`'s width is computed
  synchronously from the screen width (not measured via `GeometryReader` +
  `@State`) — `List` self-sizes a row once on first appearance, so a width
  that only becomes known a frame later leaves the row's committed height
  too short and wrapped chips get clipped. Full effect durations still live
  only on the combatant detail screen. Row is omitted entirely when nothing's active
- Reaction-used is just another chip in that row (`arrow.uturn.left`,
  labeled "Reaction"), shown alongside effect condition icons — not visually
  special-cased or called out separately from the rest
- List is always sorted highest to lowest initiative
- Every row is a card on `Theme.surface` with a hairline border. The
  current-turn row is marked three ways at once: lifted to `surfaceRaised`,
  outlined in accent, and given a solid 3pt accent bar down its leading edge.
  The bar is what makes the active row findable while scanning down the
  initiative column, which a background tint alone doesn't do. This card look
  (`View.cardRowStyle(isHighlighted:)` + `cardRowLayout()`,
  `ViewExtensions.swift`) is shared with every other list in the app
  (Creatures, Encounters, Load Session, New Session) so they all look
  consistent rather than each screen reimplementing its own row chrome

### 2. Initiative Order & Turn Advancement

**Turn Tracking**
- The app maintains a "current combatant" pointer
- "Next Turn" button (bottom right) advances to the next combatant
- After the last combatant, wraps to the first
- On turn start, that combatant's reaction is reset to "available"

**Current Turn Indicator**
- The combatant whose turn it is is highlighted or marked distinctly
- Useful for quick reference during play

### 3. Reaction Tracking

**Reaction State**
- User-facing behavior unchanged: reaction available/used, defaults to available,
  toggled from the combatant detail screen, persists until their next turn begins
- **Internally**, implemented as a regular `Effect` (`.untilStartOfTheirTurn`,
  marked `isReactionMarker: true`) appended to the combatant's own `effects`
  array via `CombatSession.useReaction`/`resetReaction`/`toggleReaction`, rather
  than a separately-stored bool with its own reset step. It expires through the
  exact same `removeExpiredEffects` pass every other effect uses — `nextTurn()`
  no longer needs a bespoke "reset reaction" line at all. `Combatant.reactionUsed`
  is now a computed property (`effects.contains { isReactionMarker == true }`),
  so read call sites didn't need to change
- Hidden from the user-facing effects list (`Combatant.visibleEffects` filters
  it out) — it has its own dedicated Reaction UI, so showing it a second time
  in "Active Effects" would be redundant
- Visual indicator: `arrow.uturn.left` (a half-circle back-turning arrow —
  available in accent color, used in muted tertiary color; same glyph both
  states, just recolored). Went through a few earlier choices (`bolt.fill`/
  `bolt.slash.fill`, `hand.tap`/`hand.tap.fill`, `arrow.triangle.2.circlepath`)
  before landing here — needed something visually distinct from every
  `ConditionLibrary` icon (see §11) so it's never confused with a status
  condition, and closer to the "arrow that goes back and forth in a half
  circle" shape than the earlier full-circle option. On the combatant detail
  screen's toggle it shows both states; on the main list it's just one more
  status chip (see §1), shown only when used, not shown at all when
  available, matching how effects only show when active rather than
  placeholders for every possible one

### 4. Temporary Effects

**Effect Definition**
An effect has:
- Name (brief descriptor, e.g., "Stunned", "Poisoned")
- Duration type + a turn count (see below)
- Applied to: the combatant being edited

**Duration Types**
An effect is always self-applied by the DM to the combatant it's on — there's no
"target's turn" concept (if it should expire on someone else's turn, put it on them
instead). Duration is start/end of the owner's own turn, repeated across however
many of their turns you specify:
1. "Until start of their turn" — expires the Nth time this combatant's turn begins
2. "Until end of their turn" — expires the Nth time this combatant's turn ends

(Where "start" = turn begins, "end" = turn advances to next combatant; N = the turn
count set when adding the effect, default 1)

**Adding an Effect**
- Tap a combatant to open their detail view
- Button to "Add Effect"
- Modal prompts for:
  - Effect name
  - Duration type (start/end of their turn)
  - Number of turns (stepper, default 1)
- Effect is added to the combatant's active effects list

**Effect Display**
- On the main list, show active effects under each combatant
- Visual distinction (e.g., colored badge or icon) for each effect
- When duration expires, effect auto-removes

**Effect Removal**
- Tapping an effect should allow manual removal
- Optional: swipe-to-delete

### 5. HP Tracking

**Opt-in per combatant.** Not every combatant needs HP tracked (e.g. a
GM-controlled NPC that's narrative-only) — `maxHP`/`currentHP` are `nil` until
explicitly enabled for that combatant, so existing sessions and the "add
combatant" flow are unaffected by default.

**Enabling & editing** (from the combatant detail screen, alongside Reaction/Effects)
- "Track HP" action prompts for a max HP value, sets `currentHP = maxHP`
- Once tracked: **Current HP** and **Max HP** are separate rows, each with
  its own inline Amount field and action button(s) right next to it, rather
  than one shared amount field feeding all three actions — Current's row
  has **Damage**/**Heal** buttons (subtracts/adds, clamped to `0...maxHP`);
  Max's row has a single **Increase Max HP** button (blue heart-plus icon,
  raises *both* max and current by the amount — a buff/level-up, not just a
  higher ceiling with no immediate benefit). Keeps each action next to the
  value it actually affects instead of Increase Max HP sitting oddly far
  from the Max HP box
- Direct numeric entry on the Current/Max HP fields themselves for exact
  corrections (e.g. after a spell effect)
- `currentHP` clamps to `0...maxHP` for Damage/Heal — no negative HP, no
  overheal past max via those two actions (Increase Max HP is the deliberate
  exception, since it moves the ceiling itself)

**Dead indicator**
- A combatant is dead when `currentHP == 0` (only meaningful if HP is tracked)
- Dead combatants get an unambiguous visual marker — not just a color change —
  on both the main list row and the detail screen (e.g. skull icon + dimmed/
  grayed row + "Dead" label), so it reads correctly even for colorblind users
  and at a glance during play
- Dead combatants **stay in turn order** (don't auto-remove) — narratively a
  character can still be dead-and-present (death saves, corpse still "acts" as
  a turn placeholder in some systems); removal is a separate explicit action
  under the existing Phase 2 "remove/edit combatant" item, not automatic
- HP display in the list (e.g. "12/20") is colored by remaining-HP fraction so
  a wounded combatant is visible without opening the detail screen

**Explicitly out of scope for now**: temp HP, overheal, damage types/resistances,
death saving throws, or any specific ruleset's dying mechanics — this tracks a
plain current/max HP number and a dead/alive boolean, system-agnostic, per the
project's standing "no copyrighted ruleset content" constraint.

### 6. Navigation & Layout

**Main Screen (Combat View)**
```
┌─────────────────────────────────┐
│  ←   [Session Name / Round N]  ☰│  (toolbar, all centered .principal)
├─────────────────────────────────┤
│                                 │
│  20  [P1: Alice]                │
│  18  [P2: Bob] (current, filled)│  (list, sorted, swipe to remove;
│  15  [P3: Carol]                │   big initiative number, far left)
│                                 │
├─────────────────────────────────┤
│  [← Previous]   [+]   [Next →]  │  (bottom bar)
└─────────────────────────────────┘
```

**Toolbar**
- **Back** (leading): icon-only (`chevron.left`, no "Menu" text) — returns to
  the main menu, autosaves first. Icon-only deliberately: it makes this item
  the same width as the trailing icon-only hamburger button, which is what
  lets `.principal` center correctly (see below)
- **Session name + Round N** (`.principal`, true center): a two-line stack —
  editable name field above, plain round counter below, neither a button.
  Works reliably in `.principal` specifically *because* the leading/trailing
  items are both single icons of equal width
- **Hamburger menu** (trailing, `line.3.horizontal`): opens a dropdown with
  "Show Player/DM View" (the DM/player-view toggle, §12) and "Log" (§9) —
  consolidates two lower-frequency actions that used to sit in the bottom
  bar, freeing that bar's middle slot for the Add-combatant button

**Bottom bar**
- **Previous Turn** (left): Reverts to the previous turn's full state (turn
  index, reactions, effects, and log entries — see §9); disabled when there's
  no prior turn to return to
- **Add Combatant** (center, `+` icon): opens the add-combatant modal
  (`AddCombatantSheet`) — replaced an earlier top-of-list inline row, a
  bottom-of-list placeholder row, and later a top-right toolbar button; all
  turned out to want a dedicated modal (fiddly small fields / accidental
  taps) reachable from a natural thumb position, so this bottom-center slot
  is now the entry point
- **Next Turn** (right): Advance to next combatant, reset current's reaction
  to available
- On iOS 26+, this whole bar uses Liquid Glass (`GlassEffectContainer`,
  `.glassProminent` on Next Turn as the primary action, `.glass` on Previous
  Turn and Add) — it's the one floating control bar in the app, the natural
  fit per Apple's glass guidance (see `<agent-config>/skills/ios-hig/SKILL.md`).
  Falls back to the existing themed bar below iOS 26. No other button in the
  app uses glass — see that skill for the full reasoning on which buttons
  qualify

**Combatant Detail** (tap a combatant row)
- Shows full combatant info
- Current reaction status with toggle
- List of active effects with removal option
- Button to "Add Effect"
- Close/back to main list

**Add Effect Modal** (from combatant detail)
- Effect name input
- Dropdown for duration type
- If target-based duration: dropdown to select target combatant
- Confirm/Cancel

## Data Model

```
struct Combatant {
    id: UUID
    name: String
    initiative: Int  // 1–20 (or higher)
    effects: [Effect]
    maxHP: Int?      // nil until HP tracking is enabled for this combatant
    currentHP: Int?  // clamped 0...maxHP; 0 == dead (isDead is derived, not stored)

    // Derived, not stored:
    // reactionUsed: Bool — effects.contains { isReactionMarker == true }
    // visibleEffects: [Effect] — effects filtered to exclude the reaction marker
}

struct Effect {
    id: UUID
    name: String
    durationType: DurationType
    isReactionMarker: Bool?  // internal use only, see "Reaction Tracking" above
    // Note: target combatant, when duration is target-based, lives inside
    // durationType itself (untilStartOfTargetTurn(targetID:)/untilEndOfTargetTurn(targetID:)),
    // not as a separate field.
}

enum DurationType {
    case untilStartOfTheirTurn
    case untilEndOfTheirTurn
    case untilStartOfTargetTurn(targetID: UUID)
    case untilEndOfTargetTurn(targetID: UUID)
}

struct CombatSession {
    combatants: [Combatant]  // ordered by initiative (desc)
    currentTurnIndex: Int  // 0-based index into sorted list
}
```

### 7. Main Menu & Session Persistence

**No explicit save.** There's no "Save Session" button or naming dialog — every combat
session is automatically saved under its own stable identity as you play. A session's
name is auto-generated from when it was created (e.g. "Session — Aug 23, 2026 1:45 PM"),
and is editable at any time — tap the name, in the toolbar's `.principal`
slot (`SelectAllTextField`, which selects all existing text on focus so
typing immediately replaces it), type a new one; blank/whitespace-only input
is ignored rather than leaving the session unnamed. This went through a
couple of iterations: `.principal` centers relative to leading/trailing
button widths, not the true phone-screen center, so it visibly skewed
whenever the two flanking toolbar items had unequal width — moved to the
screen body as a workaround for a while, then back to `.principal` once
both the leading (back arrow) and trailing (hamburger) items settled on
being single icons of equal width (see §6), which lets `.principal` center
correctly.

**Round counter**: shown directly below the session name in that same
`.principal` stack, starts at 1 and increments each time turn order wraps
back to the first combatant. Reverts correctly via "Previous Turn" and
resets to 1 on "New Session".

**Main Menu** (app launch / navigating back)
- **Resume**: loads whichever session was last active, if one still exists on disk —
  the button is hidden entirely (not just disabled) when there's nothing to resume
- **New Session**: clears all combat state and starts a fresh session (new identity)
- **Load Session**: browse all auto-saved sessions, tap to load, swipe left + confirm
  to delete

**Combat screen persistence**
- Top-left "Menu" button returns to the main menu (autosaves first)
- Autosave happens on leaving the combat screen or the app backgrounding — not on
  every micro-mutation (reaction toggle, effect add) — this is an intentional
  scope tradeoff, not a bug

**Compatibility**: once this app is actually installed/published for real use, the
on-disk `SessionRecord` format becomes a durable contract — see the "Session
persistence compatibility" section in `CLAUDE.md`. Not yet in force pre-publish.

### 8. Preset Creatures

Every combatant you add is auto-remembered by name for reuse — no explicit "save
as preset" step. Add a "Goblin" once, and adding another "Goblin" later auto-fills
its saved HP. System-agnostic and generic throughout — **no naming, branding, or
references to any specific tabletop ruleset anywhere in this feature, its code, or
its UI copy.**

**Data model**:
```
struct CreaturePreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var maxHP: Int?             // nil = no default HP, filled in per-spawn like today
    var initiativeBonus: Int?   // nil = no bonus; flat modifier added to random rolls only
}
```
Stored the same way sessions are — one JSON file per preset under a
`Presets/` directory, via a small `PresetStore` (same shape as `SessionStore`,
without the "last active" pointer concept since presets aren't a session).

**Initiative Bonus** — the generic name for "flat modifier added to a random
initiative roll" (deliberately plain, ruleset-agnostic wording; it's not shown
as a distinct field in the add-combatant modal, only applied silently there —
editing it happens in Main Menu → Creatures). Only applies when initiative is
being rolled (blank in the add modal); an explicitly typed initiative value is
used exactly as given, bonus ignored. `CombatSession.addCombatant`/
`addCombatants` both take an `initiativeBonus: Int = 0` parameter for this.

**Auto-save on add**: whenever a combatant is added (from the add-combatant modal,
§1), `PresetStore.upsert(name:maxHP:initiativeBonus:)` creates or updates
(case-insensitive name match) a preset with that name/HP. Initiative bonus isn't
set from the add flow (no field there) — only HP and name upsert on add; bonus is
edited exclusively from the Creatures screen. For a count>1 spawn, the upsert
still happens once using the typed base name, not the numbered per-copy names
("Goblin 1", "Goblin 2", ...).

**Editing lives in Main Menu → Creatures**, not in the add flow. That screen:
list of presets (name + HP + AC + initiative bonus), tap to edit, swipe to
delete (no confirmation dialog — swipe + tap is already two deliberate
actions), a top-right "+" to create one directly (name/HP/AC/initiative
bonus, same fields as editing) — presets don't have to originate from actually
adding a combatant in a session; either path works. There is no restore action;
see Default Content.

**Default presets** (shipped so the list isn't empty on first launch) — generic
folklore archetypes, common across fantasy tabletop games generally, not tied to
any one ruleset, with HP/AC/initiative bonus chosen to feel plausible rather than
copied. The roster itself is **not reproduced here** — it's ~70 entries and would
be stale within a session; see `Stores/DefaultContent.swift`, and the Default
Content section below for how it's installed and kept additive.

**Explicitly out of scope for now**: preset categories/tags, importing/sharing
preset packs, per-preset default effects, manual preset creation outside the
add-combatant flow — keep it to name + HP + initiative bonus until there's a
concrete need for more.

### 9. Combat Log

Feed of what's happened during the current session — opened from the **Log**
button in the bottom bar (center, between Previous/Next Turn). Grouped into
sections by round number, oldest round first; entries within a round are
chronological too — reads top-to-bottom like a chat log. Opens scrolled to
the bottom (most recent entry) via `ScrollViewReader`, since that's almost
always what you want to see first.

**What gets logged**: turn changes ("Alice's turn", "Round 2 began"), damage,
healing, max-HP increases (including the implicit baseline set when HP
tracking starts, whether at add-time or later via "Track HP"), deaths,
combatants added/removed. Reaction toggles are deliberately *not* logged —
too frequent/low-value to be worth the noise.

**Editable, scoped to HP.** HP-affecting entries (damage, healing, max-HP
increase, HP-tracking-started) can be swiped away to correct a mistake —
deleting one **recomputes that combatant's current/max HP from scratch** by
replaying its remaining HP-operation entries, in order (`CombatSession.
deleteLogEntry`/`recomputeHP`). Structured data (`HPOperation` enum: which
operation + amount, plus the target `combatantId`) backs this; the entry's
`text` is only ever the display rendering, never parsed back. Turn changes,
combatant add/remove, and death entries are **not** deletable yet — no
defined "undo" for those without touching turn order, which is a materially
bigger and riskier change (see the design discussion this was scoped down
from, in project history). Deleting the damage entry that caused a death
naturally revives the combatant, since `isDead` is derived from `currentHP`,
which the recompute restores.

**Revert-aware**: `Previous Turn` doesn't just revert combatant/turn state — it
truncates the log back to exactly where it was before the turn being undone,
using the same `history` snapshot stack already powering turn revert (each
snapshot now also records the log's length at that point). Nothing shows in
the log for a turn that's no longer considered to have happened.

**Persisted** with the session (`SessionRecord.log`, optional for backward
compatibility with sessions saved before this existed — decodes as an empty
log). Cleared on `New Session`.

### 10. Armor Class

Opt-in per combatant, mirrors HP (`Combatant.armorClass: Int?`, `CreaturePreset.
armorClass: Int?`). Editable from the combatant detail screen (alongside Name/
Initiative), the add-combatant modal, and the Creatures/Encounters editors.
"Armor Class"/"AC" is a generic mechanical term used across many tabletop
systems — not trademarked, confirmed before adding this.

### 11. Standard Conditions

`ConditionLibrary` (`Conditions.swift`) ships a fixed list of standard status
conditions — Blinded, Charmed, Deafened, Frightened, Grappled, Incapacitated,
Invisible, Paralyzed, Poisoned, Prone, Restrained, Stunned, Unconscious,
Exhausted, Burning, Bleeding — each with an SF Symbol icon and a
`ConditionCategory`. Plain
generic English condition words, not trademarked or ruleset-specific (single
descriptive words like "stunned" aren't ownable), and SF Symbols are licensed
for in-app UI use on Apple platforms (not for app icons/logos, which doesn't
apply here).

- **Add Effect** gets a "Choose Condition" menu above the free-text name field
  — picking one fills the name; the free-text field still accepts anything
  custom, conditions are a convenience, not a restriction
- Effect badges (combatant list row, "Active Effects" on the detail screen)
  look up the effect's name against the library (case-insensitive) and show
  the matching icon/color; unrecognized/custom effect names fall back to a
  generic sparkle icon in the theme accent color
- **Color comes from the condition's category, not the condition** — see
  "Condition colors are information, not decoration" under Design & Theming for
  the five categories and why per-condition hues were dropped
- No new duration mechanism — conditions use the same `DurationType` cases
  (and auto-expiry) as any other effect

Explicitly excluded from this app: legendary/lair actions (tabletop RPG-specific
mechanic, no generic equivalent worth building), held/delayed turns, private
per-combatant notes — all considered and declined on direct instruction.

### 12. DM / Player View

A single toggle (`CombatSession.playerViewEnabled`, not persisted — always
starts in DM view on load/resume) controls whether HP/AC show exact numbers
or an approximate read, for when the DM's screen is visible to players.
There is exactly one control for it, in the toolbar's hamburger menu (§6) —
not duplicated per-screen — so it's unambiguous which state you're in no
matter which screen you're looking at.

- **Main combatant list**: shows HP/AC (when set) right under initiative —
  exact numbers ("14/20 HP", "AC 15") in DM view, the same approximate bands
  as the detail screen in player view. Omitted entirely for a combatant with
  neither set
- **Combatant detail screen always shows exact editable HP/AC**, regardless
  of the toggle — tapping into a creature is a deliberate DM action, not
  something a player glances at over their shoulder the way the main list
  might be, so there's no approximate mode here. The toggle only affects the
  main list (below)

### 13. Encounters

Prepare a named creature list ahead of time, then start a session already
populated with it — for prep before a session instead of adding combatants
one at a time at the table.

**Data model**: `Encounter { id, name, entries: [EncounterEntry] }`,
`EncounterEntry { id, name, maxHP?, armorClass?, initiativeBonus?, count }`.
Entries are **snapshots**, not live references to a `CreaturePreset` — editing
or deleting a preset later doesn't retroactively change an encounter that used
it. `EncounterStore` persists one JSON file per encounter, mirroring `SessionStore`/
`PresetStore`.

- **Main Menu → Encounters**: create/edit/delete encounters. Editing an
  encounter lets you add creatures either by picking a saved preset (prefills
  name/HP/AC/initiative bonus) or typing custom values directly, plus a count
  per entry; swipe to delete an entry or the whole encounter (no extra
  confirmation dialog, matching the pattern used elsewhere)
- **Starting from one**: Main Menu → **New Session** opens a dedicated list
  screen (`NewSessionView`, `Route.newSessionChooser`) — "Fresh Session" or
  any saved encounter by name, styled like every other list in the app
  (`cardRowStyle`). Replaced an earlier `confirmationDialog` action sheet,
  which looked out of place as the one native-chrome sheet in an otherwise
  fully custom-themed app. Picking an encounter resets the session then
  calls `addCombatants` once per entry; initiative is always rolled fresh
  per combatant at start time (never stored in the encounter itself) — an
  encounter is a creature list, not a frozen turn order

## UI/UX Principles

- **Minimal, clean design**: No unnecessary clutter; focus on reading turn order and state at a glance
- **Fast interactions**: Add combatant, use reaction, add effect should be quick taps
- **Clear feedback**: Visual distinction for current turn, effect status, reaction availability
- **Scalable**: Works with 2–20+ combatants without performance degradation

## Default Content

`Stores/DefaultContent.swift` holds the starter creature roster and the ready-made
encounters, as one table each. Encounters name their creatures and the stats are
resolved at install time rather than restated, so there's one place a stat is
written down; `DefaultContentTests` fails if an encounter names a creature that
isn't in the roster, which would otherwise install combatants with no HP or AC
and nothing at runtime would object.

**Defaults are additive, never all-or-nothing.** `installDefaults()` runs on every
launch on both stores and installs any built-in that isn't currently present:

| Situation | Behaviour |
|---|---|
| Built-in missing (new this version, or renamed away) | installed |
| User already has a preset with that name | left alone — their version is never overwritten |

The rule this replaced, "seed only if the store is empty", meant defaults added
in a later version never reached anyone who had already used the app, and a
single custom creature made before first launch permanently cost you the whole
roster.

**Built-in content is read-only and permanent.** A built-in creature or encounter
cannot be deleted, renamed, or edited — the library is a fixture, not a starting
point to be whittled down. Concretely:

- No Delete swipe action on a built-in row; it offers **Duplicate** instead.
- Tapping one opens the same sheet with every field disabled and **Duplicate**
  where Save would be. Showing the familiar fields greyed out makes the
  relationship between original and copy obvious in a way a separate detail
  screen wouldn't.
- `PresetStore.upsert` — which runs whenever a combatant is added — **refuses to
  modify a built-in**. Adding a combatant called "Goblin" with 12 HP would
  otherwise quietly rewrite the built-in Goblin's stats: an edit to read-only
  content through the back door, from a screen that isn't even the Creatures list.
- Copies are named `"Goblin Copy"`, then `"Goblin Copy 2"`… (`UniqueName`), and
  land in **Yours**, where they're fully editable and deletable.

This also removes the need for a "Restore Defaults" action, and for any memory of
what has been installed before: since a built-in can't be deleted, anything
missing is either new in this version or something the user renamed into a
creature of their own, and either way belongs back in the list. `installDefaults()`
is therefore a plain what's-missing check run on every launch.

### Browsing the libraries

Creatures and Encounters are the same screen twice — a saved library mixing what
shipped with the app and what the user has built — so they're presented
identically, from `Common/ListSections.swift` and `Common/SearchBar.swift`:

- **Two sections, "Yours" above "Included"**, so the handful of things you made
  aren't buried in seventy built-ins. Origin is decided by *name* rather than a
  stored flag: renaming a default makes it yours, editing its stats doesn't. That
  needs no change to the on-disk format and can't fall out of step with the
  default roster. An empty section is hidden entirely rather than shown as a bare
  header.
- **Search pinned at the bottom of the screen**, not the system `.searchable`
  bar under the title — it's where the thumb is on a phone held one-handed at a
  table, and the combat screen already puts its controls in a bottom bar, so it
  reads as the same shape rather than a second convention. Its chrome matches
  that bar: page color, hairline top edge, nothing else.
- Terms are ANDed but may match different fields, so narrowing works ("giant
  spider" doesn't return every Giant) and an encounter is findable by what's
  *in* it ("troll boar" finds Bridge Troll). Matching is
  `localizedStandardContains` — case- and diacritic-insensitive, as user-facing
  search should be.
- No results shows `ContentUnavailableView.search(text:)`; the bar itself is
  hidden when the library is empty, since there's nothing to filter.

## Design & Theming

**Everything visual comes from tokens.** `Common/Theme.swift` is the single
source of truth for color, spacing (`Theme.Spacing`, a 4pt scale), corner radius
(`Theme.Radius`) and type (`Theme.Typography`). A view must not contain literal
padding numbers, corner radii, `Color(red:…)` values, or bare `.font(.headline)`
calls — if a value is missing, a token gets added rather than a one-off written
inline. `Common/ViewExtensions.swift` holds the shared modifiers built on those
tokens (`themedScreen`, `cardRowStyle`/`cardRowLayout`, `sectionCard`,
`fieldStyle`, `Text.sectionLabel`, `Text.cardHeading`); each exists because the
same chrome had been copy-pasted across several screens and drifted apart.

No screen falls back to system-default white/black — a `Form`/`List` is white by
default and needs `.scrollContentBackground(.hidden)` + `themedScreen()` (see
`ContentView`). Native system *components* (`Form`/`Section`, `List`,
`ContentUnavailableView`, swipe actions, confirmation dialogs) are still
preferred over hand-rolled containers; it's specifically *colors* that must come
from `Theme`, not a mandate to reskin every control. The navigation bar is the
one thing SwiftUI can't color at all, so it's set once through
`Theme.applyNavigationBarAppearance()` from `RootView.init` — without it the bar
stays on UIKit's neutral system gray and reads as a foreign slab.

### Structure is fixed; the palette is chosen

Two rules are the load-bearing part of the design, and **no theme gets to opt out
of either** — they're what makes the app readable mid-combat:

1. **Depth comes from surfaces, not borders.** There's a real elevation ladder —
   `background` → `surface` (cards, list rows) → `surfaceRaised` (inputs, chips,
   the current-turn row) — plus a very low-contrast gradient
   (`backgroundGradient`) so a full screen doesn't read as a flat block. Outlines
   are hairline weight (`Theme.hairline`, 0.75pt) at reduced opacity; a
   full-weight 1pt stroke on every element is what makes a UI read as "boxes
   drawn around things". The ladder always runs *toward the light*, including in
   the light palette — Parchment's steps get whiter as they come forward rather
   than being a dark ladder inverted.
2. **The accent marks at most one thing per screen.** `Theme.accent` is the only
   saturated color in normal use, and it only reads as emphasis if nothing else
   competes with it. On the combat screen it's spent on the current turn
   (initiative numeral, leading edge bar, outline) and the primary action;
   non-current initiative numbers are `textSecondary`. Anything else that needs
   to stand out uses a status or condition-category color, never the accent.

### Themes

Colors are values, not constants: `ThemePalette` holds the whole set,
`ThemeIdentifier` enumerates the selectable ones, and `Theme`'s color
accessors forward to whichever `ThemeController` has selected. Views never name a
palette — they say `Theme.surface` and get re-rendered on change automatically,
because `ThemeController` is `@Observable` and SwiftUI tracks observable reads
through static accessors. That's what made theming possible without editing every
view to thread an environment value through.

| Theme | Ground | Accent | Notes |
|---|---|---|---|
| **Tavern Candlelight** (default) | warm near-black | candle gold | The original. A dark room lit by one flame. |
| **Ink & Cinnabar** | cool blue-black | cinnabar red | Warm off-white text on a cool ground — a printed-page relationship rather than a screen one, which is what carries the serif without reading as generic-fantasy. Red already means urgency, so `conditionOngoing` moves to a cold acid green to keep red meaning one thing. |
| **Slate & Brass** | blue-grey stone | muted brass | The quiet one; least flavour, most legible. `conditionRestraint` is clay rather than the bronze the warm palettes use, since bronze is indistinguishable from brass. |
| **Verdigris** | dark grey-green | oxidised copper | An accent from the ground's own family but far more saturated, so it reads as metal in the wall. `conditionDisabling` gives up teal here — teal is the accent's neighbourhood — and takes magenta. |
| **Abyssal** | blue-black | bioluminescent cyan | The only palette whose accent is *colder* than its ground, which is worth having precisely because every other theme warms up to mark the current turn. |
| **Nightshade** | violet-black | luminous green | Green is the ground's complement rather than a brighter version of it. `conditionMental` is pushed hard toward pink, since violet is the room's colour here and a violet chip would say nothing. |
| **High Contrast** | pure black | bright yellow | Not a mood — a legibility setting for a badly lit table or tired eyes. The one palette that deliberately breaks the muted-colors rule, with stronger borders too. |
| **Parchment** | warm paper (light) | oxblood | Offered, never the default: a white phone at a dim table is a flashlight in everyone's face. Status and condition colors are darkened across the board — mid-tones that work on black wash out on paper. |
| **Vellum** | cool grey paper (light) | deep teal | The second light theme earns its place because paper white and screen white read as different materials, and which one a room flatters varies. |

A palette also declares its `colorScheme`, forced app-wide from `RootView`, so
everything system-drawn (keyboard, native toolbar chrome, `Form`/`List` defaults)
follows the theme rather than the device setting. Selection persists in
`UserDefaults` under `selectedTheme`; an unrecognised stored value falls back to
the default rather than failing. The picker is **Main Menu → Appearance**
(`AppearanceView`), which draws each option in its own colors — a palette is the
one setting whose label genuinely can't describe the choice — and splits dark
from light, since a table with the lights down rules out half the list before
taste enters into it.

**`ThemePaletteTests` checks the design rules against every palette**, not just
the selected one: the elevation ladder is monotonic and each step perceptible,
text meets WCAG contrast on every surface it sits on (AAA primary / AA secondary
/ AA-large tertiary), `accentForeground` is legible on `accent`, the declared
`colorScheme` matches how the palette actually paints, and no condition or status
color sits within 0.3 RGB of the accent. Writing those down caught two real
collisions by hand-tuned eye: Tavern's amber `statusWarn` was 0.09 from candle
gold (a "Wounded" band read as a second current-turn marker), and Parchment's top
two elevation steps were only 1.07:1 apart.

Semantic status colors (`statusGood`/`Warn`/`Bad`/`Neutral`/`Info`) carry
health/armor bands and the Damage/Heal/Increase-Max-HP buttons — muted, warm
versions of red/green/blue rather than raw SwiftUI `.red`/`.green`/`.blue`, which
read as too saturated here. `placeholderText` exists because SwiftUI's plain
`TextField("placeholder", text:)` always renders its placeholder in a fixed
system gray regardless of theme; every placeholder-bearing field uses the
`TextField(text:label:)` closure form so the placeholder can be recolored.

### Condition colors are information, not decoration

Each standard condition used to carry its own hue chosen to suit the word
("Poisoned" green, "Charmed" pink, "Stunned" yellow, …). That meant a combatant
with four effects showed four unrelated saturated colors, none of which told the
DM anything the label didn't already say, and one of them (yellow) sat close
enough to candle gold to compete with the current-turn marker.

Conditions are now grouped into five `ConditionCategory` cases by *what they do
to you* — `sensory`, `mental`, `restraint`, `disabling`, `ongoing` — and the
color comes from the category. A glance at chip color says which kind of trouble
a combatant is in, and the palette stays small enough to sit inside any of the
four schemes. The hues themselves live in `ThemePalette` rather than beside the
conditions, because they have to be retuned per theme (a color that sits happily
beside candle gold can land on top of cinnabar); what's fixed is the constraint,
asserted for every palette in `ThemePaletteTests`. Icons stay per-condition and
are asserted unique, since the glyph is what distinguishes conditions *within* a
category.

### Typography

The voice is **a serif for anything that names something, tabular figures for
anything numeric**:
- Serif (`Typography.display`/`.title`/`.rowTitle`, and the nav bar title):
  screen titles, combatant names, creature/encounter/session names, card
  headings. This is what gives the app a character of its own instead of reading
  as default-SF-everywhere.
- Rounded monospaced digits (`Typography.numeric`/`.stat`/`.statLarge`):
  initiative, HP, AC. Functional, not stylistic — these sit in columns, and
  proportional digits make the columns visibly jitter between values.
- Tracked uppercase captions (`Text.sectionLabel()`): field and section labels.
  At caption size, letter-spaced caps read as a deliberate label rather than as
  undersized body text. Card titles use `Text.cardHeading()` instead — a
  different *kind* of type, not a brighter version of the same caps, so a card's
  title never reads as one more field label inside it.
- All styles build on Dynamic Type text styles, so they still scale with the
  user's text size setting.

### Spacing & shape

- Every gap and inset comes from `Theme.Spacing` (4pt scale: 4/8/12/16/24/32).
- Corner radii come from `Theme.Radius` (6/10/14), using `.continuous` style.
- Tap targets stay at or above 44pt.

## Architecture Decision Record (ADR)

### ADR-001: Use XcodeGen for project management
**Decision**: Manage the iOS project via `project.yml` and XcodeGen, not hand-edited `.xcodeproj`.

**Rationale**:
- `.pbxproj` is large XML that's hard to diff and merge
- `project.yml` is readable YAML, easy to version control
- Regeneration is deterministic—no divergence between git state and Xcode state

**Impact**: Always edit `project.yml` and run `xcodegen generate` after project structure changes.

### ADR-002: SwiftUI + Preview-driven development
**Decision**: Use SwiftUI (not UIKit) with Canvas Previews for iteration.

**Rationale**:
- SwiftUI is the modern Apple standard, composable and type-safe
- Canvas Previews give immediate visual feedback during development
- Smaller code surface for a personal app

**Impact**: Every view should have a `#Preview` block; test UI visually during development.

## Planned: one mechanism for everything that ticks

**Not implemented.** This supersedes the earlier separate proposals for
caster-anchored durations, recharge timers and save-based reminders — they turned
out to be the same feature seen from three angles.

### The observation

The app already has three things that are secretly one thing:

- an **effect** (a name that expires after N turn boundaries),
- the **reaction marker** (an effect with a flag on it), and
- anything the DM currently tracks in their head because the app can't hold it.

Everything in that third category has the same shape: *a named thing attached to
a combatant, which resolves at a particular turn boundary, by one of a small
number of rules.* A dragon's breath weapon isn't a new feature — it's an effect
whose resolution rule happens to be "roll a d6 and see" instead of "count down
from 1". Building recharge, save-ends, ongoing damage and concentration as four
separate features is exactly how this screen would get cluttered; building one
mechanism with four resolution rules is how it doesn't.

### The shape

Two fields on `Effect`, both orthogonal, neither multiplying the other's cases:

```swift
struct Effect {
    var name: String
    var kind: EffectKind          // .condition | .cooldown        (new, defaults .condition)
    var anchorID: UUID?           // whose turn it keys off; nil = the owner  (new)
    var durationType: DurationType
}

enum DurationType {
    case untilStartOfTheirTurn(remainingTurns: Int)   // today, unchanged
    case untilEndOfTheirTurn(remainingTurns: Int)     // today, unchanged
    case recharge(die: Int, succeedsOn: Int)          // rolled at the anchor's turn start
    case untilSaveSucceeds(timing: TurnBoundary)      // prompts; never auto-expires
    case manual                                       // sits until removed by hand
}
```

**`anchorID` is a field, not more enum cases.** The earlier proposal folded the
anchor into the duration (`.untilStartOfCombatantTurn(anchorID:…)`), which
doubles the case count for a concern that varies independently of how the effect
resolves. As a field it composes: any resolution rule can key off anyone's turn.
`nil` means the owner, so every existing effect keeps its meaning and the common
case needs no UI.

**`kind` exists only to change wording and weight**, not behaviour. A *condition*
is something wrong with you; a *cooldown* is something you can't do yet. They
expire identically, but "Breath Weapon" shouldn't shout in the same red as
"Burning" — cooldown chips take the quiet `textTertiary` treatment the reaction
chip already uses. It also retires `isReactionMarker`: reaction-used becomes a
cooldown with a one-turn duration, which is what it always was.

### What this then supports

| Mechanic | Expressed as |
|---|---|
| Reaction used | cooldown, `.untilStartOfTheirTurn(1)` — what it already is |
| **Dragon's breath, recharge 5–6** | cooldown, `.recharge(die: 6, succeedsOn: 5)` |
| Once per encounter | cooldown, `.manual` |
| Stunned, save ends | condition, `.untilSaveSucceeds(.endOfTurn)` |
| Blinded for 3 rounds | condition, `.untilEndOfTheirTurn(3)` — what it already is |
| Held by a spell the caster maintains | condition on the target, `anchorID` = caster |

### The turn prompt

The second half, and the part that makes it usable rather than merely
expressible: when a combatant's turn begins, anything of theirs needing attention
is surfaced **once, together**, not as badges to notice.

- `.recharge` rolls automatically and reports the result ("Breath Weapon
  recharged — rolled 5"). The app already rolls d20 for initiative, so rolling a
  d6 here is consistent with what it does, not a new kind of thing. The roll goes
  through the existing log, which is also the undo mechanism, so a roll the DM
  doesn't want is one swipe from gone.
- `.untilSaveSucceeds` asks ("Save for Wren: Frightened?") with **Saved** /
  **Not yet**. The app never resolves the save — that's the DM's call, and the
  standing no-rules-automation line stays exactly where it is. What's added is
  the reminder, not the ruling.
- One sheet per turn, dismissible, never blocking. Nothing appears when there's
  nothing pending, which is most turns.

### Keeping it uncluttered

Four rules, and they're the whole reason this is one feature and not six:

1. **One mechanism, not one feature per mechanic.** Anything that ticks is an
   effect with a resolution rule. New mechanics should arrive as new rules, and
   if a mechanic can't be expressed as one, that's a signal to reconsider it
   rather than to add a parallel system.
2. **The default path doesn't change.** Adding "Stunned for 2 turns" involves
   exactly the taps it does today. `kind` defaults to `.condition`, `anchorID`
   defaults to the owner.
3. **Complexity is quick-picked, not configured.** A small `CooldownLibrary`
   (Recharge 5–6, Recharge 6, Recharge 4–6, Once per encounter) sits beside the
   existing condition chips, so the common cases are one tap. The anchor picker
   and a custom die live behind an **Advanced** disclosure that is closed by
   default and that most sessions never open.
4. **Nothing new on the combat list unless it's live.** Chips already work this
   way; cooldowns join them in the quiet treatment rather than adding a row.

### Also worth having, in rough priority order

Each is a resolution rule or a small field, not a subsystem:

1. **Ongoing damage** — "5 fire at the start of your turn". An amount on an
   effect, applied at its boundary through the existing HP log so it's undoable
   and shows up in the log like any other damage. The `ongoing` condition
   category already exists and currently only means a colour; this makes it mean
   something. Cheapest real win on this list.
2. **Concentration** — a link from an effect to the caster maintaining it, so
   that dropping or ending concentration clears everything it holds up. Needs
   `anchorID` plus a prompt when the anchor takes damage. Common enough at the
   table to be worth it.
3. **Limited uses** — "3 charges left", a counter that decrements on tap. Fits as
   a `.manual` cooldown carrying a count.
4. **Death saves** — a 3-successes/3-failures counter for a downed combatant.
   Today "dead" is binary. This is a per-combatant counter rather than an effect,
   so it's the one item here that doesn't fold into the mechanism above.
5. **Temporary HP** — absorbs damage before real HP. A field on `Combatant` and a
   change to how damage applies; touches the HP log's undo, so not free.
6. **Round-anchored effects** — "at the start of round 4, the bridge collapses",
   or an environmental effect on a fixed initiative count. Anchored to the round
   rather than to any combatant; would need `anchorID` to become an enum
   (`.combatant(UUID)` / `.round`) rather than an optional.

**Declined**, for the same reasons as before: auras and zones (needs a map, and
this app deliberately has no spatial model), legendary and lair actions as
first-class mechanics (excluded on direct instruction; a lair action is
expressible as a round-anchored effect if item 6 ever lands), and anything that
resolves a rule rather than reminding the DM to.

### Migration note

`Effect` and `DurationType` are a durable on-disk format
(`CodableCompatibilityTests` guards this). New fields must decode as absent —
`kind` → `.condition`, `anchorID` → `nil` — and the existing `isReactionMarker`
has to keep decoding until the cooldown kind can be relied on to have replaced
it. That's a decode-side alias, not a data migration.

## Non-Goals

- Cross-platform (Android, web)
- Complex state management libraries (Redux, MobX) until needed
- Extensive third-party dependencies
- Character sheet integration or detailed stat tracking
- Resolving rules on the DM's behalf. Rolling *is* in scope where the app is
  the natural place for it — initiative already rolls, and recharge would (see
  the planned effects work) — but attack/damage/save resolution is not
- Network multiplayer (local single-device only)
- Audio notifications or detailed sound design
- Deep customization of rules or mechanics (keep it generic/system-agnostic)
