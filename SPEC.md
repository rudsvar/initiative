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
- **Still filtered out of `Combatant.visibleEffects`** (it's not an `Effect`
  the DM applies, just internal implementation for the free-riding expiry), but
  no longer hidden from the *UI* — it's a chip in the combatant detail screen's
  Actions card (see "Concentration" above), not a dedicated card of its own
- Visual indicator: `arrow.uturn.left` (a half-circle back-turning arrow). Went
  through a few earlier choices (`bolt.fill`/`bolt.slash.fill`, `hand.tap`/
  `hand.tap.fill`, `arrow.triangle.2.circlepath`) before landing here — needed
  something visually distinct from every `ConditionLibrary` icon (see §11) so
  it's never confused with a status condition. Same grid treatment as any other
  chip: grayscale when available, colorful with a checkmark when used, one tap
  to flip it. On the main roster list it's just one more status chip (see §1),
  shown only when used, matching how effects only show when active rather than
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
2. "Until end of their turn" — expires the Nth time this combatant's turn ends.
   Put on during the combatant's own turn, the end of that turn doesn't count:
   "until the end of their next turn" lasts through their next turn.

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

**Enabling & editing** (`HealthControlRow` — the roster's expanded current
combatant and the detail screen's Health card both use the same component)
- "Track HP" action prompts for a max HP value, sets `currentHP = maxHP`
- Once tracked: three lines in one layout, **Current HP**, **Temp HP** and
  **Max HP**, each with its value, a − button, a number box for the amount and
  a + button. Current HP: − is damage, + is healing (healing past max asks
  whether to go above max as temporary HP or cap at max). Temp HP: + adds to
  it, − takes it off and never touches real hit points; it is logged as a
  grant of the new total, or as damage the buffer absorbs in full, so the log
  replays to the same result with no new operation. Max HP: lowered or raised
  directly; raising also raises current HP (a buff or level-up). Temporary HP
  never stacks: a new grant keeps the larger (see below)
- **On the roster, a buffed number is bold and coloured, with no amount.**
  Current HP shows the total in play (temporary HP included, as AC includes
  temporary AC) and is bold green while temporary HP lasts; AC is bold blue
  (the shield's colour) while temporary AC lasts. A max HP or AC change is bold
  green (blue for AC) or red until that
  combatant's turn starts. How much of it is temporary or changed is only on
  the detail screen: a "+N" under each number was tried and dropped as
  clutter
- Direct numeric entry on the Initiative/AC fields (detail screen) still
  exists for exact corrections; Current/Max HP themselves are edited only
  through the buttons above, not a raw text field

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

**Setting values directly**: tapping Current, Max or Temp HP in `HealthControlRow` opens a box to type the value. Corrections only: no temporary HP absorption, current clamped to `0...maxHP`, max at least 1 (current comes down with it, never up), temp 0 clears. Each is logged (`setCurrentHP`, `setMaxHP`, `setTemporaryHP`) and replays.

**Armor class card** uses the same line as health (`AmountControlLine`): tap AC or Temp AC to type it, − / amount / + to lower or raise it.

**Rules as written**
- Temporary HP absorbs damage first and is not healed; two grants keep the larger.
- A player reduced to 0 HP by damage that carries at least max HP past zero dies outright.
- Damage taken at 0 HP is a failed death save; it also ends a stable state.
- Max HP can be lowered to 0, which kills. Raising it raises current HP by the same amount.
- Concentration prompt: DC is 10 or half the damage, whichever is higher.
- Healing past max can be turned into temporary HP as an optional choice (not in the rules).

**Explicitly out of scope**: overheal, damage types/resistances, or any
specific ruleset's dying mechanics beyond the generic death-saves flow above —
this tracks a plain current/max HP number, an optional temporary-HP buffer,
and a dead/alive boolean, system-agnostic, per the project's standing "no
copyrighted ruleset content" constraint. (Temporary HP itself, listed as
out-of-scope in an earlier draft of this section, was added — see the
`temporaryHP` field and `grantTemporaryHP`.)

### 6. Navigation & Layout

**Main Screen (Combat View)**
```
┌─────────────────────────────────┐
│ ← ▤  [Session Name / Round N] 👁 +│  (toolbar, title on the centre line)
├─────────────────────────────────┤
│                                 │
│  20  [P1: Alice]                │
│  18  [P2: Bob] (current, filled)│  (list, sorted, swipe to remove;
│  15  [P3: Carol]                │   big initiative number, far left)
│                                 │
├─────────────────────────────────┤
│  [↩ Previous]          [Next →] │  (bottom bar)
└─────────────────────────────────┘
```

**Toolbar**: two icons on each side, grouped into one capsule per side, so
both sides are about the same width and the title sits on the screen's centre
line without being measured.
- **Back** (leading, `chevron.left`, no "Menu" text): returns to the main menu,
  autosaves first
- **Log** (leading, `list.bullet.rectangle`): opens the session log (§9). Chosen
  over `list.bullet.clipboard` because it is about as wide as the eye opposite;
  the narrower clipboard pulled the title about 10 points off-centre
- **Session name + Round N** (`.principal`): a two-line stack, editable name
  field above, plain round counter below, neither a button. It fills the space
  between the two sides. A tap anywhere else on the screen ends editing
- **Player View** (trailing, `eye.fill`, `eye.slash.fill` while on): the
  DM/player-view toggle (§12), one tap
- **Add Combatant** (trailing, `+`, in the corner): opens the add-combatant
  modal (`AddCombatantSheet`), the same top-right corner this action sits in on
  every other screen (Creatures, Encounters)
- Tried and dropped: a ⋯ menu beside + (the title went off-centre, and
  measuring it back into place left an invisible title over the back button
  that swallowed taps), a ⋯ menu in the bottom bar (its menu grew oddly out of
  the glass), a small options sheet, the log behind the round counter, and the
  four buttons in the bottom bar in pairs

**Bottom bar** (`TurnControlBar`): Previous and Next, two separate circular
buttons at the ends where the thumbs are.
- **Previous** (`arrow.uturn.backward`, the undo arrow, since it reverts;
  the media-style `backward.fill` it replaced read as "skip back"):
  reverts to the previous turn's full state (turn index, reactions, effects,
  and log entries — see §9); disabled when there's no prior turn to return to
- **Next** (`arrow.right`, not `forward.fill`, which read as "skip";
  accent-tinted/prominent to read as the primary
  action): advance to next combatant, reset current's reaction to available
- On iOS 26+ each button gets its own `.glassProminent`/`.glass` style inside
  a shared `GlassEffectContainer` (Next prominent, Previous not) —
  it's the one floating control surface in the app, the natural fit per
  Apple's glass guidance (see the `ios-hig` skill). Falls
  back to plain circular buttons below iOS 26. No other button in the app
  uses glass — see that skill for the full reasoning on which buttons qualify
- Floats over the roster via `.safeAreaInset(edge: .bottom)` rather than
  sitting in a plain `VStack` beside the list — combatant rows are visible
  scrolling behind it instead of stopping dead above a hard-edged bar

**Combatant Detail** (tap anywhere on a row — pushed, not inline)
- Top bar shows the combatant's name in an editable field (same
  select-all-on-focus behavior as the session name in the main toolbar) —
  there's no separate Name field elsewhere on the screen
- Identity card: Initiative and Armor Class fields
- Health card: `HealthControlRow` — current/max readout plus damage/heal/
  grant-temp-HP/increase-max-HP buttons, each prompting for its amount via
  an inline alert
- Actions card: Reaction, Concentration, and any `LimitedUse` resources
- Effects card: the full two-column condition/cooldown grid, named
  cooldowns/custom effects list, "Add Limited Use…", "Custom effect…"
- The roster row's own read-only status strip shows conditions/cooldowns
  (`combatant.visibleEffects`) and, first, a Concentrating chip while the
  combatant concentrates, since damage can break it and the DM needs to see
  that at a glance. Reaction is not shown there, only on this screen. Two designs that tried to unfold this content
  in place under the roster row instead of pushing to it — a chevron on
  every row, and before that an auto-expanding current-combatant row — were
  each tried and reverted (see "Declined" below); a pushed screen is what
  ships

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
both the leading (back arrow) and trailing (add) items settled on being
single icons of equal width (see §6), which lets `.principal` center
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
button in the toolbar, top left (§6). Grouped into
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
deleteLogEntry`/`replayHP`). Structured data (`HPOperation` enum: which
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

On the detail screen the Armor Class card has two lines in the Health card's
layout (`AmountControlLine`, shared by both cards): **Armor Class** and **Temp
AC**, each with − / amount / +. Temporary AC is added to armor class for the
fight and taken off by hand, never touching the base. Tapping any number on either card asks for an exact value
(0 removes a temporary amount); see "Setting values directly". The roster shows the total
in play, bold blue while temporary AC lasts.

### 11. Standard Conditions

`ConditionLibrary` (`Conditions.swift`) ships a fixed list of standard status
conditions — Blinded, Charmed, Deafened, Frightened, Grappled, Incapacitated,
Invisible, Greater Invisible, Paralyzed, Poisoned, Prone, Restrained, Stunned,
Unconscious, Exhausted, Burning, Bleeding — each with an SF Symbol icon and a
`ConditionCategory`. Plain
generic English condition words, not trademarked or ruleset-specific (single
descriptive words like "stunned" aren't ownable), and SF Symbols are licensed
for in-app UI use on Apple platforms (not for app icons/logos, which doesn't
apply here).

- The combatant detail screen's "Effects" card shows every standard condition
  (plus the single `StandardCooldown`) as a chip in a **fixed two-column
  grid**, grayscale until tapped — not a wrapping row of variable-width chips,
  so every chip gets the same, larger tap target regardless of label length.
  **One tap applies it with its usual duration** and turns the chip colorful
  with a checkmark; tapping it again removes it — there's no separate "Manage"
  screen between opening a combatant and changing what's wrong with them. A
  gear icon appears on an active chip only, for the minority of cases that need
  a different duration than the default guessed (`EffectEditorView`, see
  below). Custom (non-standard) effects still go through a name field, via a
  "Custom effect…" row below the grid.
- Effect badges (combatant list row, the same grid on the detail screen) look
  up the effect's name against the library (case-insensitive) and show the
  matching icon/color; unrecognized/custom effect names fall back to a generic
  sparkle icon in the theme accent color
- **Color comes from the condition's category, not the condition** — see
  "Condition colors are information, not decoration" under Design & Theming for
  the five categories and why per-condition hues were dropped
- No new duration mechanism — conditions use the same `DurationType` cases
  (and auto-expiry) as any other effect

Explicitly excluded from this app: legendary/lair actions (ruleset-specific
mechanic, no generic equivalent worth building), held/delayed turns, private
per-combatant notes — all considered and declined on direct instruction.

### 12. DM / Player View

A single toggle (`CombatSession.playerViewEnabled`, not persisted — always
starts in DM view on load/resume) controls whether HP/AC show exact numbers
or an approximate read, for when the DM's screen is visible to players.
There is exactly one control for it, the eye button in the toolbar, top right (§6) —
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
  screen (`NewSessionView`, `Route.newSessionChooser`) — "Fresh Session", then
  saved encounters split into "Yours" and "Included" sections (same
  `ListSections.split` the Encounters library itself uses, so a user's own
  prepared encounters aren't buried among the built-ins), styled like every
  other list in the app (`cardRowStyle`). Replaced an earlier
  `confirmationDialog` action sheet, which looked out of place as the one
  native-chrome sheet in an otherwise fully custom-themed app. Picking an
  encounter resets the session then
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

Creatures, Encounters, and New Session are presented identically, from
`Common/ListSections.swift` and `Common/SearchBar.swift`:

- **Two sections, "Yours" above "Included"**, so the handful of things you made
  aren't buried in seventy built-ins. Origin is decided by *name* rather than a
  stored flag: renaming a default makes it yours, editing its stats doesn't. That
  needs no change to the on-disk format and can't fall out of step with the
  default roster. An empty section is hidden entirely rather than shown as a bare
  header. The label itself is a plain row inside the `Section`, not the
  `header:` slot — `List` in `.plain` style pins that slot so it floats and
  trails the scroll instead of moving with its own rows, and a page-local
  grouping label shouldn't behave like a sticky navigation element.
- **Search is the system's own `.searchable` field** (`View.appSearchable`),
  not a hand-built bar — a fully custom bottom-docked pill was tried and
  reverted for reading too wide and too heavy next to how search actually
  looks on iOS 26. On iOS 26+ it's paired with `.searchToolbarBehavior
  (.minimize)`, the same native glass-search pattern stock apps use (Notes,
  Files, Photos); below iOS 26 it falls back to plain `.searchable`, still
  fully native.
- Terms are ANDed but may match different fields, so narrowing works ("giant
  spider" doesn't return every Giant) and an encounter is findable by what's
  *in* it ("troll boar" finds Bridge Troll). Matching is
  `localizedStandardContains` — case- and diacritic-insensitive, as user-facing
  search should be.
- No results shows `ContentUnavailableView.search(text:)`; search itself is
  hidden when the library is empty, since there's nothing to filter.

## Design & Theming

**Everything visual comes from tokens.** `Common/Theme.swift` is the single
source of truth for color, spacing (`Theme.Spacing`, a 4pt scale), corner radius
(`Theme.Radius`) and type (`Theme.Typography`). A view must not contain literal
padding numbers, corner radii, `Color(red:…)` values, or bare `.font(.headline)`
calls — if a value is missing, a token gets added rather than a one-off written
inline. `Common/ViewExtensions.swift` holds the shared modifiers built on those
tokens (`themedScreen`, `CardRowButtonStyle`/`cardRowLayout`, `sectionCard`,
`fieldStyle`, `Text.sectionLabel`, `Text.cardHeading`); each exists because the
same chrome had been copy-pasted across several screens and drifted apart.
The one deliberate exception is `TurnPromptView`'s sheet background
(`.presentationBackground(.regularMaterial)`, §9 "The turn prompt") — native
sheet chrome (drag indicator, corner radius, dimmed backdrop) is drawn by the
system and doesn't know about this app's palette, so a custom fill there
looked out of place no matter which `Theme` color it used; the system's own
material is what actually matches it.

No screen falls back to system-default white/black — a `Form`/`List` is white by
default and needs `.scrollContentBackground(.hidden)` + `themedScreen()` (see
`ContentView`). Native system *components* (`Form`/`Section`, `List`,
`ContentUnavailableView`, swipe actions, confirmation dialogs) are still
preferred over hand-rolled containers; it's specifically *colors* that must come
from `Theme`, not a mandate to reskin every control. The navigation bar is the
one thing SwiftUI can't color at all, so it's set once through
`Theme.applyNavigationBarAppearance()` from `RootView.init` — below iOS 26,
without it the bar stays on UIKit's neutral system gray and reads as a foreign
slab, so it's painted with an opaque `Theme.backgroundLift` fill. On iOS 26+ the
same function instead configures a *transparent* bar, deliberately — that's
what lets the system's native floating Liquid Glass title bar show through,
with list content visible scrolling up underneath it. An opaque custom
background would defeat that: it doesn't just look flat, it paints over
content that's already scrolling behind the bar either way.

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

## Effects, prompts and death saves

### One mechanism for everything that ticks

The app has one shape for temporary state: **a named thing on a combatant that
resolves at a turn boundary**. An effect, the reaction marker, a recharging
ability and a save-ends condition are all that shape with a different rule for
how they resolve — which is why they're one mechanism rather than a feature
each. `Effect` carries a `kind` (`.condition` — something wrong with you —
or `.cooldown` — something you can't do yet), which changes only wording and
weight: cooldown chips take the quiet `textTertiary` treatment the reaction chip
already uses, because "Breath Weapon" shouldn't shout in the same colour as
"Burning".

`DurationType.untilRollSucceeds(at:hint:)` is the case that doesn't count down.
It sits there until the DM says a roll succeeded, and `removeExpiredEffects`
deliberately passes it over. **A recharge and a save-ends condition are the same
thing seen from two sides** — *at this boundary, something gets rolled, and on a
success this goes away* — differing only in the verb, which `kind` supplies. That
is entirely a consequence of the app not rolling: had it rolled, the two would
have needed separate rules for evaluating and reporting.

**Effects that end on an action** are asked about, not rolled. Invisible ends
when its owner attacks, deals damage or casts a spell, which the app can't see,
so as the owner's turn ends a prompt asks "Did Wren attack, deal damage or cast
a spell?" with "Yes, it ends" and "No". It is matched by name, like Burning, so
nothing new is saved. Greater Invisible isn't broken that way: it never asks,
and lasts ten of its owner's turns (a minute).

`hint` is free text (`"DC 14 Con"`), shown in the prompt and nowhere else so
chips stay short. It is never parsed. `StandardCooldown` offers a "Recharge"
one-tap quick-pick so the extra capability stays out of the way until it's
wanted — it used to offer three DC-specific variants (Recharge 5–6/6/4–6), which
turned out to be the app inventing clutter of its own: the DM already knows
what to roll for, and "Recharge" needs no number attached to remind them that a
roll is owed.

### The turn prompt

Rolls owed at a turn boundary are collected **once, together, and must all be
answered** (`TurnPromptView`) — but shown **one at a time**, not stacked. A
stacked list was the original design; with several owed together (a couple of
death saves plus a recharge, say) it had no `ScrollView`, so the self-sizing
sheet measured a height taller than the screen with no way to reach what
didn't fit — not scrollable, and dragging the sheet couldn't expand it past
its own fixed detent either. Now it shows only the next unanswered prompt
("Roll 2 of 3") and advances automatically as each is answered, which also
keeps the sheet's height bounded regardless of how many are owed. Freely
dismissible (swipe away) at any point — nothing is applied until every
prompt has an answer, so backing out mid-prompt can't half-advance the
turn; worst case the same prompts reappear the next time you try to
advance. Nothing appears when nothing is owed, which is most turns.

The sheet's background is the system's own material
(`.presentationBackground(.regularMaterial)`), a deliberate, scoped exception
to "everything visual comes from `Theme`" (see Design & Theming) — a flat
custom fill was tried first and, even once made a single consistent color,
still looked out of place against sheet chrome the system itself draws (drag
indicator, corner radius, dimmed backdrop), which doesn't know about this
app's palette. `.regularMaterial` is what native sheets actually use and
adapts to light/dark automatically, so this popup reads as a normal iOS
sheet rather than a themed card wearing sheet chrome.

**Tapping an answer resolves it immediately — there is no Continue button.**
This is the middle of combat: a mis-tap is rare, and cheap to fix by hand
(reopen the effect, flip it back). Paying for that rare case with a second
confirming tap on every single roll was the wrong trade, so the sheet dismisses
itself the instant the last prompt has an answer.

- End-of-turn rolls for the combatant whose turn is finishing and start-of-turn
  rolls for the one whose turn is beginning are shown **together**, even though
  they belong to different combatants: it's one interruption at the boundary
  rather than two either side of it.
- Answers are handed to `nextTurn(resolving:)` rather than applied separately, so
  they land **inside the same undo step** as the advance. Previous rewinds the
  save you just recorded along with the turn it belonged to.
- **A compact modal, not a full screen.** `TurnPromptView` measures its own
  content height and feeds it back into `.presentationDetents` rather than
  claiming a fixed fraction of the display — a one-line prompt gets a one-line
  sheet instead of a `.medium` detent floating it in mostly empty space.
- **The app never rolls and never decides.** Its job is remembering that a roll is
  owed. Everything the DM answers goes through the log, so it's visible and
  undoable like any other event.

### Player and NPC combatants

`isPlayer` on both `CreaturePreset` and `Combatant`. Built-in creatures are NPCs;
anything the user creates by hand defaults to **player**, since the built-in
roster already covers the bestiary and a creature typed in from scratch is most
often a party member. The toggle is visible in the Add Combatant sheet at the
moment of creation rather than inferred later — the tempting heuristic ("count >
1 means monsters") would be right often enough to be trusted and wrong often
enough to hurt.

Only death saves use it today. Player view does not use it: it hides every
combatant's numbers, party included, because the party does not necessarily share
their hit points with each other (rudi, 2026-11-17).

### Configuring a duration

`EffectEditorView` is deliberately down to two questions, because the grid
already covers the common case in one tap: which edge of the owner's turn it
keys off (**start** or **end** of their turn), and whether it clears on a roll
or after a fixed number of turns — a **"Requires a save" toggle, on by
default**, that reveals a turns stepper when switched off. There is no option
for "until removed" here: a condition that clears itself (Prone standing up,
Grappled escaping) is cleared the same way it was applied — tapping the chip
off again — not through a duration setting, so the screen never needs a third
choice to express it. A roll hint set by a `StandardCooldown` template (none
currently set one, but a future one might) is carried through unedited if the
DM only adjusts boundary/turns; the screen doesn't expose it, so reconfiguring
a recharge can't accidentally erase what it was rolling for.

### Concentration

A bare `Bool` on `Combatant`, not an `Effect` — deliberately, because it has
nothing to configure: no name, no duration, just on or off. Naming what's being
concentrated on ("Hold the Bridge") was tried and dropped — it made
concentration cost as much attention as a condition, for a mechanic that's
supposed to be a single toggle the DM flips once and forgets until it's
threatened. It's a chip in its own "Actions" card, above Effects rather than
inside it — alongside Reaction and any `LimitedUse` resources — since all
three are checked every single turn regardless of which conditions are active,
and neither Reaction nor Concentration has a gear (nothing to configure).
Taking damage while it's on raises the same `TurnPrompt` mechanism everything
else uses, with the same inverted sense as before (failure ends it, success
keeps it), and being dropped to 0 HP ends it without asking, since there's
nothing left to roll for.

**Offered, never assumed.** When a condition is put on someone during another
combatant's turn (a chip tap or a new custom effect), the app asks "Is Alpha
concentrating on Frightened?" with Concentrating / No, since it was most likely
Alpha's spell. Not asked when the effect goes on the current combatant itself,
when they already concentrate, or for a cooldown. Yes sets the flag and logs
"Alpha started concentrating on Frightened"; the name isn't kept, as above.

Reaction tracking (§3) sits in the same card for the same reason: neither it
nor concentration is "wrong with you" or "can't do yet" like a condition or
cooldown, but both are a plain on/off a DM checks constantly, so treating them
as chips beats giving each a dedicated section to scroll past.

### Limited Use

A named, countable resource — Legendary Actions, a "3/day" ability — that gets
spent down over the fight rather than toggled on/off (a condition) or waited on
for one roll (a cooldown). `LimitedUse` (`name`, `total`, `remaining`) lives on
`Combatant` as its own array, not as an `Effect`: none of the four `DurationType`
shapes mean anything for "how many are left," so forcing it into that enum would
mean cases only one feature uses.

- **Created via a compact modal** (name + a count stepper) reached from "Add
  Limited Use…" in the Actions card — there's no sensible default count to
  guess the way a condition's usual duration can be, so the DM is asked once,
  up front, rather than getting a default they immediately have to fix.
- **Spent one tap at a time**, same motion as `Reaction`, but counting down
  instead of flipping a bool; the cog (always present, not just once "active"
  like a condition's — a limited use always has something to configure) reopens
  the same modal to rename it, change the count, or remove it.
- **Refills when the round turns over, not on the combatant's own turn.** This
  is the one place it diverges from `Reaction`'s rule: a Legendary Action
  budget is meant to be spent across every *other* combatant's turns within the
  round, so tying its refill to its own owner's turn — the way `Reaction`
  works — would hand it back before it had the chance to be spent. Both still
  reset through hooks in the same `nextTurn()`, just at different moments in it.
- Replaces "Once per encounter" (a `StandardCooldown` with `.untilRemoved`,
  see above) — that was the same idea with the count hardcoded to exactly one,
  and it's what changed this from something declined to something built: see
  "Declined" below.

### Death saves

**A player** who hits 0 HP starts rolling death saves. **An NPC** at 0 HP is
simply dead, exactly as before — which is the entire reason the tag exists, since
otherwise every killed goblin would acquire a clock.

At the start of a dying combatant's turn the prompt asks for the outcome, one
tap: **Success** or **Failure**. Three successes stabilises, three failures
kills. Both are tracked because both count — you can fail twice and be healed, or
succeed three times and stabilise.

This is the one piece of temporary state that deliberately **isn't** an `Effect`.
Everything else resolves one way; here both outcomes matter, and bending
`DurationType` to carry two tallies plus a death-on-failure rule would give it a
case with five associated values that exactly one thing uses. What *is* shared is
the turn prompt.

Three states have to stay distinguishable, and the row shows each differently:
**dying** (a filled `statusBad` badge, at full opacity — it's the most
time-critical thing on the screen, and fading it would say the opposite),
**stabilised** (0 HP, not rolling, explicitly not dead), and **dead**. Healing
above 0 ends the situation outright; so does deleting the log entry for the blow
that caused it, since the log is the HP undo mechanism and leaving someone
rolling death saves at full health would be worse than either.

## Round-anchored effects

Effects belonging to the fight rather than to any creature in it — a collapsing
bridge, an environmental hazard, anything that fires at the top of the round.
They live on `CombatSession.roundEffects` rather than on a combatant, and that's
the whole point: pinning one to whichever creature was handy is wrong in a way
that bites, because the effect vanishes when that creature dies or is removed,
and it fires on their turn instead of at the top of the round. There's a test for
each of those.

- **`DurationType.forRounds(remaining:)`** counts down when the round turns over,
  not on anyone's turn. `.untilRemoved` and `.untilRollSucceeds` work here too;
  the turn-anchored cases don't, and are inert if one somehow appears.
- **Rolls come due when the round wraps**, riding on the advance that increments
  it. `TurnPrompt.combatantID` is therefore optional — the round belongs to no
  one — and such a prompt is labelled "The round".
- Ticking, undo and persistence all follow the existing paths: round effects are
  part of the history snapshot, so Previous restores a countdown, and part of
  `SessionRecord` (optional, so older saves load empty).

**In the UI**: a pinned strip above the roster, shown only when something is in
play — they belong to the fight, not to any row, and a strip above the list is
what says so without needing a label to explain it. Managing them is a separate
screen (`RoundEffectsView`) rather than a mode of the per-combatant Effects
card, because almost nothing carries over: there are no conditions to pick from
(a bridge isn't Frightened), no concentration, and the durations differ. Sharing
the screen would have meant most of it being conditionally hidden.

This is also the route to lair-action-style mechanics, which were declined as a
first-class feature but are expressible this way.

### Declined

Deliberately not building, each considered and dropped:

- **Ongoing damage amounts** and **linked concentration** (losing concentration
  clearing the effects it held up) — both were on the list and are no longer
  wanted. The mechanism could carry them; the appetite isn't there, and an
  unwanted feature costs the same to maintain as a wanted one.
  (**Limited-use counters**, previously declined alongside these two, were
  reinstated as `LimitedUse` — see "Limited Use" above — once a concrete need
  showed up for them: Legendary Actions and similar per-fight resources.)
- **Auras and zones** — needs a spatial model, and this app deliberately has none.
- **Legendary and lair actions as first-class mechanics** (one published ruleset's specific rules
  for when they trigger and what they cost) — excluded on direct instruction.
  `LimitedUse` is a generic countable resource a DM can point at that use case,
  same as round-anchored effects are the generic route to lair-action-style
  triggers — neither bakes in the ruleset itself.
- **Anything that resolves a rule** rather than reminding the DM to.
- **Unfolding combatant detail in place under a roster row**, tried two ways:
  first an auto-expanding current-combatant row with a reduced control set
  (Reaction/Concentration but not initiative/AC/Limited Uses), then a chevron
  on every row unfolding the full `CombatantDetailView` content. Both were
  reverted for the same underlying reason: SwiftUI's `List` animates a row's
  own height change internally regardless of whether the app code requests an
  animation, and no reliable way was found to suppress it — an explicit
  `.animation(value:)` and, separately, a `disablesAnimations` transaction
  wrapping the toggle were each tried and the row's own text still visibly
  slid/flew as it resized. Pushing to `CombatantDetailView` (see "Combatant
  Detail" above) sidesteps the whole class of bug, since there's no List row
  being resized.

## Non-Goals

- Cross-platform (Android, web)
- Complex state management libraries (Redux, MobX) until needed
- Extensive third-party dependencies
- Character sheet integration or detailed stat tracking
- Rolling or resolving anything the DM hasn't explicitly asked for. The app's
  job is to remember that a roll is owed and record the outcome. It will roll on
  request — initiative when a combatant is added, a recharge or death save via
  the prompt's **Auto** button — but only where it can evaluate the whole roll
  itself, and never as the default answer. Saving throws against a DC, attacks
  and damage stay off the table entirely: they need modifiers the app doesn't
  track and shouldn't start tracking.
- Network multiplayer (local single-device only)
- Audio notifications or detailed sound design
- Deep customization of rules or mechanics (keep it generic/system-agnostic)
