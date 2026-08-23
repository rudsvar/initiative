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
- Remove/edit combatant
- Round counter display
- Visual indicators for effects and reaction state
- Haptic feedback on turn advance

### Phase 3: HP Tracking (planned, not yet implemented — see below)
- Per-combatant current/max HP, opt-in (not every combatant needs it tracked)
- Quick damage/heal adjustment
- Clear "dead" indicator when HP reaches 0

## Core Features

### 1. Combatant Management

**Add Combatant**
- Inline placeholder row pinned at the top of the combatant list (no modal)
- Name and initiative are separate bordered text boxes (each its own tappable
  field, per iOS HIG — see `<agent-config>/skills/ios-hig/SKILL.md`), with the add
  (+) button outside/after the initiative box, not touching it
- Leaving initiative blank rolls random 1–20 on add
- Submitting (return key or the + button) adds the combatant and clears the row, ready for the next entry
- Combatants auto-sort by initiative (descending; ties maintain insertion order)

**Combatant Display**
- List shows: name, initiative number, reaction status, active effects
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
- Each combatant has a boolean: reaction available (true) or used (false)
- Default: true (available)
- Clicking a combatant reveals an option to "Use Reaction" or "Reset Reaction"
- "Use Reaction" sets their state to unavailable (used)
- State persists until their next turn begins (at which point it auto-resets to available)
- Visual indicator on the list shows reaction status (e.g., checkmark = available, X = used)

### 4. Temporary Effects

**Effect Definition**
An effect has:
- Name (brief descriptor, e.g., "Stunned", "Poisoned")
- Duration type (see below)
- Optional target combatant (required if duration references "target's turn")
- Applied to: the combatant being edited

**Duration Types**
1. "Until start of their next turn" — expires when this combatant's turn begins again
2. "Until end of their next turn" — expires when this combatant's turn ends
3. "Until start of target's next turn" — expires when the named target's turn begins
4. "Until end of target's next turn" — expires when the named target's turn ends

(Where "start" = turn begins, "end" = turn advances to next combatant)

**Adding an Effect**
- Tap a combatant to open their detail view
- Button to "Add Effect"
- Modal prompts for:
  - Effect name
  - Duration type
  - If duration involves a target, show a picker of all other combatants
- Effect is added to the combatant's active effects list

**Effect Display**
- On the main list, show active effects under each combatant
- Visual distinction (e.g., colored badge or icon) for each effect
- When duration expires, effect auto-removes

**Effect Removal**
- Tapping an effect should allow manual removal
- Optional: swipe-to-delete

### 5. HP Tracking (planned — not yet implemented, awaiting confirmation before build)

**Opt-in per combatant.** Not every combatant needs HP tracked (e.g. a
GM-controlled NPC that's narrative-only) — `maxHP`/`currentHP` are `nil` until
explicitly enabled for that combatant, so existing sessions and the "add
combatant" flow are unaffected by default.

**Enabling & editing** (from the combatant detail screen, alongside Reaction/Effects)
- "Track HP" action prompts for a max HP value, sets `currentHP = maxHP`
- Once tracked: quick +/- damage/heal controls, plus direct numeric entry for
  exact values (e.g. correcting after a heal spell)
- `currentHP` clamps to `0...maxHP` — no negative HP, no overheal past max for
  now (temp HP / overheal is out of scope until there's a concrete need)

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
│  + Add combatant…      [Init] │  (inline placeholder row, top)
├─────────────────────────────────┤
│                                 │
│  [P1: Initiative 20]            │
│  [P2: Initiative 18] (current)  │  (list, sorted)
│  [P3: Initiative 15]            │
│                                 │
├─────────────────────────────────┤
│  [Back]          [Next Turn →]  │  (bottom)
└─────────────────────────────────┘
```

**Buttons**
- **Add combatant row** (top): Always-visible inline row; fill in name (and optional initiative) and submit to add, no modal
- **Previous Turn** (bottom left): Reverts to the previous turn's full state (turn index, reactions, effects); disabled when there is no prior turn to return to
- On iOS 26+, the Previous/Next Turn bar uses Liquid Glass (`GlassEffectContainer`,
  `.glassProminent` on Next Turn as the primary action, `.glass` on Previous Turn) —
  it's the one floating control bar in the app, the natural fit per Apple's glass
  guidance (see `<agent-config>/skills/ios-hig/SKILL.md`). Falls back to the existing
  themed bar below iOS 26. No other button in the app uses glass — see that skill
  for the full reasoning on which buttons qualify
- **Next Turn** (bottom right): Advance to next combatant, reset current's reaction to available

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
    reactionUsed: Bool  // false = available, true = used
    effects: [Effect]
    maxHP: Int?      // planned (Phase 3) — nil until HP tracking is enabled for this combatant
    currentHP: Int?  // planned (Phase 3) — clamped 0...maxHP; 0 == dead
}

struct Effect {
    id: UUID
    name: String
    durationType: DurationType
    targetCombatantID: UUID?  // nil unless duration is target-based
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
name is auto-generated from when it was created (e.g. "Session — Aug 23, 2026 1:45 PM").

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
