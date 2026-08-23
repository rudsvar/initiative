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
- ✅ A handful of built-in default presets to start from
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
- List shows: name, initiative number, HP/AC (when set — exact in DM view,
  approximate bands in player view, see §12), and a wrapping row of small
  chips for active statuses (reaction used + active effects) — each status
  gets its own darker rounded box (`StatusChip`, `ContentView.swift`) with
  an icon plus a short label (e.g. "Stunned", "Used"), laid out via a custom
  `FlowLayout` (`Theme.swift`, SwiftUI `Layout` protocol) so several sit side
  by side and wrap to the next line on overflow rather than clipping. Full
  effect durations still live only on the combatant detail screen. Row is
  omitted entirely when nothing's active
- Reaction-used is just another chip in that row (`hand.tap`, labeled
  "Used"), shown alongside effect condition icons — not visually
  special-cased or called out separately from the rest
- List is always sorted highest to lowest initiative
- Current combatant (whose turn it is) is visually emphasized

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
- Visual indicator: an SF Symbol — `hand.tap.fill` when available / `hand.tap`
  (outline) when used. Deliberately not `bolt.fill`/`bolt.slash.fill`: those
  are already used by the Paralyzed/Incapacitated standard conditions (see
  §11), and reaction needs its own distinct icon so it's never confused with
  either. On the combatant detail screen's toggle it shows both states; on
  the main list it's just one more status chip (see §1), shown only when
  used, not shown at all when available, matching how effects only show when
  active rather than placeholders for every possible one

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
- Once tracked: a single amount field feeds three actions, all in one row as
  equal icon-only buttons next to the field (minus/plus/up-heart) rather than
  a separate labeled-button row per action — **Damage** (subtracts, clamps
  at 0), **Heal** (adds, clamps at current max), and **Increase Max HP**
  (raises *both* max and current by the amount — a buff/level-up, not just a
  higher ceiling with no immediate benefit)
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
│ ← Menu                     Add  │  (toolbar)
│      [Session Name] (centered)  │  (body, not toolbar — true screen center)
│         Round N (centered)      │
├─────────────────────────────────┤
│                                 │
│  [P1: Initiative 20]            │
│  [P2: Initiative 18] (current)  │  (list, sorted, swipe to remove)
│  [P3: Initiative 15]            │
│                                 │
├─────────────────────────────────┤
│  [← Previous] [Log][eye] [Next →]│  (bottom bar)
└─────────────────────────────────┘
```

**Toolbar**
- **Menu** (leading): returns to the main menu, autosaves first
- **Add** (trailing): opens the add-combatant modal (`AddCombatantSheet`) —
  replaced an earlier top-of-list inline row and, before that, a bottom-of-list
  placeholder row; both approaches turned out to want a dedicated modal (fiddly
  small fields / accidental taps), so this is now the sole entry point

**Body (above the list)**
- **Session name**: editable text field, centered to the true phone-screen
  center (not the toolbar's `.principal` slot — see §7 for why), blank input
  ignored
- **Round N**: plain centered text below the name, not a button, not in the
  toolbar

**Bottom bar**
- **Previous Turn** (left): Reverts to the previous turn's full state (turn
  index, reactions, effects, and log entries — see §9); disabled when there's
  no prior turn to return to
- **Log** (center, icon-only): opens a read-only feed of what's happened in
  combat (§9)
- **Eye icon** (center, next to Log, small): the sole DM/player-view toggle
  (§12) — deliberately here rather than in the toolbar, see §7
- **Next Turn** (right): Advance to next combatant, reset current's reaction
  to available
- On iOS 26+, this whole bar uses Liquid Glass (`GlassEffectContainer`,
  `.glassProminent` on Next Turn as the primary action, `.glass` on Previous
  Turn and Log) — it's the one floating control bar in the app, the natural
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
and is editable at any time — tap the name, centered at the top of the combat
screen (`SelectAllTextField`, which selects all existing text on focus so
typing immediately replaces it), type a new one; blank/whitespace-only input
is ignored rather than leaving the session unnamed. Lives in the screen body
(`.frame(maxWidth: .infinity, alignment: .center)`), not the nav bar's
`.principal` toolbar slot — that slot centers relative to leading/trailing
button widths, not the true phone-screen center, and visibly skews once
leading ("Menu", icon+text) and trailing ("Add", icon-only) have unequal
widths. Tried putting it back in `.principal` once already (after the eye
icon moved out of the toolbar) and it was still off — a body-level row is
the only fix that reliably lands on the true center regardless of toolbar
contents, same approach used for the bottom bar's Log button.

**Round counter**: shown centered below the session name ("Round N"), starts at 1 and
increments each time turn order wraps back to the first combatant. Reverts correctly
via "Previous Turn" and resets to 1 on "New Session".

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
actions), and a top-right "+" to create one directly (name/HP/AC/initiative
bonus, same fields as editing) — presets don't have to originate from actually
adding a combatant in a session; either path works.

**Default presets** (shipped so the list isn't empty on first launch) — generic
archetypes, common across fantasy tabletop games generally, not tied to any one
ruleset. HP values are researched to feel like plausible low-level creature
toughness, described here in our own generic terms only:
| Preset | Rough HP | Initiative Bonus | Notes |
|---|---|---|---|
| Goblin | 7 | +2 | small, fragile skirmisher archetype |
| Skeleton | 13 | +2 | undead melee archetype, moderately tougher |
| Thief | 11 | +3 | quick, lightly-armored humanoid archetype |
| Orc | 15 | +1 | bulkier melee brute archetype |
| Wolf | 11 | +2 | fast, fragile beast archetype |
| Zombie | 22 | −2 | slow, tanky undead archetype |
| Guard | 11 | +1 | armored humanoid archetype |
| Ogre | 59 | −1 | big, slow brute archetype |
| Giant Spider | 26 | +3 | ambush predator archetype |
| Giant Rat | 7 | +2 | weak, swarming filler archetype |
| Cultist | 9 | +1 | fragile low-level caster/minion archetype |

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
Exhausted, Burning, Bleeding — each with an SF Symbol icon + color. Plain
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
- No new duration mechanism — conditions use the same `DurationType` cases
  (and auto-expiry) as any other effect

Explicitly excluded from this app: legendary/lair actions (tabletop RPG-specific
mechanic, no generic equivalent worth building), held/delayed turns, private
per-combatant notes — all considered and declined on direct instruction.

### 12. DM / Player View

A single small eye-icon toggle (`CombatSession.playerViewEnabled`, not
persisted — always starts in DM view on load/resume) controls whether HP/AC
show exact numbers or an approximate read, for when the DM's screen is
visible to players. There is exactly one control for it, in the bottom bar
next to the Log button — not duplicated per-screen — so it's unambiguous
which state you're in no matter which screen you're looking at.

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
- **Starting from one**: Main Menu → **New Session** now opens a chooser
  (`confirmationDialog`) — "Fresh Session" or any saved encounter by name.
  Picking an encounter resets the session then calls `addCombatants` once per
  entry; initiative is always rolled fresh per combatant at start time (never
  stored in the encounter itself) — an encounter is a creature list, not a
  frozen turn order

## UI/UX Principles

- **Minimal, clean design**: No unnecessary clutter; focus on reading turn order and state at a glance
- **Fast interactions**: Add combatant, use reaction, add effect should be quick taps
- **Clear feedback**: Visual distinction for current turn, effect status, reaction availability
- **Scalable**: Works with 2–20+ combatants without performance degradation

## Design & Theming

**Current priority: native, modern iOS UI over the custom theme.** Screens should
default to standard system components (`Form`/`Section`, `List`, `ContentUnavailableView`,
system tint/materials, native swipe actions and confirmation dialogs) rather than
hand-rolled custom-styled views. The rust-red/old-paper theme below is applied
selectively (currently: the combat combatant list) rather than everywhere — see the
"Styling & Colors" note in `CLAUDE.md` and the `ios-hig` skill
(`<agent-config>/skills/ios-hig/SKILL.md`) before building a new screen.

**Color Palette** — old paper with a bold red accent, used selectively (see `Theme.swift`,
the single source of truth for these colors where the theme is applied):
- **Background**: Off-white / cream (#F5F1ED or similar)
- **Primary text**: Dark brown/charcoal (#2B2520 or similar)
- **Accent**: Saturated red (#C7241C or similar — deliberately more red than rust) for
  highlights, active states, current turn
- **Secondary accent**: Muted tan/beige (#D4C4B8) for subtle dividers, disabled states
- **Borders**: Thin accent-red or dark brown lines for card/row separation

**Typography**
- Clean, readable serif or sans-serif (e.g., SF Pro or similar default iOS)
- Combatant names: larger, bold
- Initiative numbers: prominent, rust red
- Effects: smaller, secondary text color

**Visual Elements**
- Subtle texture or grain on background to evoke aged paper (optional, via pattern or asset)
- Round corners on combatant cards/rows for softness
- Rust red highlight or background for current turn combatant
- Icons for reaction status (✓ or ✗ in rust red)
- Effect badges with muted background, rust text

**Spacing**
- Generous padding around interactive elements for easy tapping
- Clear visual hierarchy: title > combatant > effect

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

## Non-Goals

- Cross-platform (Android, web)
- Complex state management libraries (Redux, MobX) until needed
- Extensive third-party dependencies
- Character sheet integration or detailed stat tracking
- Dice rolling or complex rules automation
- Network multiplayer (local single-device only)
- Audio notifications or detailed sound design
- Deep customization of rules or mechanics (keep it generic/system-agnostic)
