# Project Specification

## Overview

**initiative** is a personal iOS application. The scope and feature roadmap are defined here.

## Target Platform & Requirements

- **Platform**: iOS 17+
- **Device**: phone
- **Development Environment**: Xcode 15+
- **App Type**: Native SwiftUI single-window application
- **Bundle ID**: xyz.rudsvar.initiative

## Core Goals

Build a clean, minimal initiative tracker for managing turn order and temporary effects in tabletop combat. The app maintains participant order, tracks reactions, and manages duration-based effects across multiple turn types.

## Feature Roadmap

### Phase 0: Foundation (Current)
- ✅ Project scaffold with SwiftUI & XcodeGen
- ✅ Runnable starter app on phone
- ⏳ MVP feature implementation

### Phase 1: MVP (Combat Tracking)
- ✅ List view of participants sorted by initiative (descending)
- ✅ Add participant with custom or random (1–20) initiative
- ✅ Next Turn button to advance turn order
- ✅ Reaction tracking per participant (reset on their turn)
- ✅ Temporary effects with multiple duration types
- ✅ Effect target selection
- ✅ Back button to return to prior state (undo stack of full session snapshots)

### Phase 2: Polish
- ✅ Combat session persistence (save/load) + main menu (Resume / New / Load)
- Remove/edit participant
- Round counter display
- Visual indicators for effects and reaction state
- Haptic feedback on turn advance

## Core Features

### 1. Participant Management

**Add Participant**
- Inline placeholder row pinned at the top of the participant list (no modal)
- Name and initiative are separate bordered text boxes (each its own tappable
  field, per iOS HIG — see `<agent-config>/skills/ios-hig/SKILL.md`), with the add
  (+) button outside/after the initiative box, not touching it
- Leaving initiative blank rolls random 1–20 on add
- Submitting (return key or the + button) adds the participant and clears the row, ready for the next entry
- Participants auto-sort by initiative (descending; ties maintain insertion order)

**Participant Display**
- List shows: name, initiative number, reaction status, active effects
- List is always sorted highest to lowest initiative
- Current participant (whose turn it is) is visually emphasized

### 2. Initiative Order & Turn Advancement

**Turn Tracking**
- The app maintains a "current participant" pointer
- "Next Turn" button (bottom right) advances to the next participant
- After the last participant, wraps to the first
- On turn start, that participant's reaction is reset to "available"

**Current Turn Indicator**
- The participant whose turn it is is highlighted or marked distinctly
- Useful for quick reference during play

### 3. Reaction Tracking

**Reaction State**
- Each participant has a boolean: reaction available (true) or used (false)
- Default: true (available)
- Clicking a participant reveals an option to "Use Reaction" or "Reset Reaction"
- "Use Reaction" sets their state to unavailable (used)
- State persists until their next turn begins (at which point it auto-resets to available)
- Visual indicator on the list shows reaction status (e.g., checkmark = available, X = used)

### 4. Temporary Effects

**Effect Definition**
An effect has:
- Name (brief descriptor, e.g., "Stunned", "Poisoned")
- Duration type (see below)
- Optional target participant (required if duration references "target's turn")
- Applied to: the participant being edited

**Duration Types**
1. "Until start of their next turn" — expires when this participant's turn begins again
2. "Until end of their next turn" — expires when this participant's turn ends
3. "Until start of target's next turn" — expires when the named target's turn begins
4. "Until end of target's next turn" — expires when the named target's turn ends

(Where "start" = turn begins, "end" = turn advances to next participant)

**Adding an Effect**
- Tap a participant to open their detail view
- Button to "Add Effect"
- Modal prompts for:
  - Effect name
  - Duration type
  - If duration involves a target, show a picker of all other participants
- Effect is added to the participant's active effects list

**Effect Display**
- On the main list, show active effects under each participant
- Visual distinction (e.g., colored badge or icon) for each effect
- When duration expires, effect auto-removes

**Effect Removal**
- Tapping an effect should allow manual removal
- Optional: swipe-to-delete

### 5. Navigation & Layout

**Main Screen (Combat View)**
```
┌─────────────────────────────────┐
│  + Add participant…      [Init] │  (inline placeholder row, top)
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
- **Add participant row** (top): Always-visible inline row; fill in name (and optional initiative) and submit to add, no modal
- **Previous Turn** (bottom left): Reverts to the previous turn's full state (turn index, reactions, effects); disabled when there is no prior turn to return to
- **Next Turn** (bottom right): Advance to next participant, reset current's reaction to available

**Participant Detail** (tap a participant row)
- Shows full participant info
- Current reaction status with toggle
- List of active effects with removal option
- Button to "Add Effect"
- Close/back to main list

**Add Effect Modal** (from participant detail)
- Effect name input
- Dropdown for duration type
- If target-based duration: dropdown to select target participant
- Confirm/Cancel

## Data Model

```
struct Participant {
    id: UUID
    name: String
    initiative: Int  // 1–20 (or higher)
    reactionUsed: Bool  // false = available, true = used
    effects: [Effect]
}

struct Effect {
    id: UUID
    name: String
    durationType: DurationType
    targetParticipantID: UUID?  // nil unless duration is target-based
}

enum DurationType {
    case untilStartOfTheirTurn
    case untilEndOfTheirTurn
    case untilStartOfTargetTurn(targetID: UUID)
    case untilEndOfTargetTurn(targetID: UUID)
}

struct CombatSession {
    participants: [Participant]  // ordered by initiative (desc)
    currentTurnIndex: Int  // 0-based index into sorted list
}
```

### 6. Main Menu & Session Persistence

**Main Menu** (app launch / navigating back)
- **Resume**: loads the autosaved in-progress session, if one exists (disabled otherwise)
- **New Session**: clears all combat state and starts fresh
- **Load Session**: browse explicitly-named saved sessions, tap to load, swipe to delete

**Combat screen persistence**
- Top-left "Menu" button returns to the main menu (autosaves first)
- Top-right save icon prompts for a name and writes a named `SessionRecord` that
  appears under "Load Session" going forward
- Autosave happens on leaving the combat screen or the app backgrounding — not on
  every micro-mutation (reaction toggle, effect add) — this is an intentional
  scope tradeoff, not a bug

**Compatibility**: once this app is actually installed/published for real use, the
on-disk `SessionRecord` format becomes a durable contract — see the "Session
persistence compatibility" section in `CLAUDE.md`. Not yet in force pre-publish.

## UI/UX Principles

- **Minimal, clean design**: No unnecessary clutter; focus on reading turn order and state at a glance
- **Fast interactions**: Add participant, use reaction, add effect should be quick taps
- **Clear feedback**: Visual distinction for current turn, effect status, reaction availability
- **Scalable**: Works with 2–20+ participants without performance degradation

## Design & Theming

**Color Palette** — old paper with a bold red accent (see `Theme.swift`, the single source
of truth for these colors — all views reference `Theme.*`, never raw color literals):
- **Background**: Off-white / cream (#F5F1ED or similar)
- **Primary text**: Dark brown/charcoal (#2B2520 or similar)
- **Accent**: Saturated red (#C7241C or similar — deliberately more red than rust) for
  highlights, active states, current turn
- **Secondary accent**: Muted tan/beige (#D4C4B8) for subtle dividers, disabled states
- **Borders**: Thin accent-red or dark brown lines for card/row separation

**Typography**
- Clean, readable serif or sans-serif (e.g., SF Pro or similar default iOS)
- Participant names: larger, bold
- Initiative numbers: prominent, rust red
- Effects: smaller, secondary text color

**Visual Elements**
- Subtle texture or grain on background to evoke aged paper (optional, via pattern or asset)
- Round corners on participant cards/rows for softness
- Rust red highlight or background for current turn participant
- Icons for reaction status (✓ or ✗ in rust red)
- Effect badges with muted background, rust text

**Spacing**
- Generous padding around interactive elements for easy tapping
- Clear visual hierarchy: title > participant > effect

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
