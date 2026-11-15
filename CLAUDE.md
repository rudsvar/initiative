# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Working guidelines

- **Keep it simple.** The smallest change that works. No speculative
  abstractions, no features nobody asked for.
- **One implementation for shared behaviour.** When the same functionality
  appears in more than one place (a list, a picker, a clone action), it is
  built once and reused, so the places cannot drift apart. Build the shared
  piece first, then point each screen at it.
- **Test first when possible (TDD).** Write the failing test, watch it fail,
  then make it pass. This applies to all model and store logic.
- **Show the app after significant changes.** After a change to layout,
  navigation, persistence or model behaviour, boot a simulator, build, install
  and launch the app so the owner can look at it on the virtual phone. Do
  this with the commands in "Looking at UI changes" below, then say which
  screen to check.
- **Check balance with premade encounters.** When the built-in creatures or
  encounters change, simulate each premade encounter (a turn-by-turn fight with
  simple, stated assumptions) and report how the expected damage taken compares
  with the party's hit points. Keep the simulation in the test target so it runs
  with the suite.

## Rule overview

A short index of the rules that matter most. Keep it current: when a rule
changes, change it here and in the section it points to.

- **Data format changes:** any change to a saved type (`SessionRecord`,
  `Combatant`, `Effect`, `CreaturePreset`, `Encounter`) needs a test that
  decodes the previous format and a migration test, so existing saves and
  presets keep working. See "Session persistence compatibility".
- **User content is never changed silently:** never modify a custom
  (user-made) creature or encounter. Only the built-in ones are read-only, and
  the user can change a built-in only through Clone, which makes their own
  copy. See "Default content".
- **Test first:** new logic and every bug fix get a test; see "Testing".
- **Show the app:** after significant UI, navigation, persistence or model
  changes, install and launch in the simulator and name the screen to check.
  See "Looking at UI changes".
- **Balance:** when built-in creatures or encounters change, run the premade
  encounter simulation; see "Working guidelines".
- **Public repo:** no trademark names and no copyrighted material unless its
  licence allows it; see "Public repo rules".

## Public repo rules (read before any commit)

This repo is meant to be public. Everything committed is public, including
history, docs, comments and test data. Before every commit and push, check the
change against these rules:

- **Trademarks:** the repo contains no trademark names, in code, docs, names,
  assets, history or listing text. The list of banned names is not committed:
  it lives in `scripts/banned-terms.local` (git-ignored), and
  `scripts/public-check.sh` reads it. The app is "for tabletop RPGs".
- **Copyright:** no copyrighted material unless its licence allows it, and
  then the licence terms are followed exactly. SRD 5.2.1 stat blocks (CC BY
  4.0) are the current case: they are marked `// SRD 5.2.1` in
  `DefaultContent.swift`, and `NOTICE` keeps the SRD's attribution statement
  word for word. Do not write a comment that says numbers are "not copied"
  unless that is true.
- **Personal information:** the copyright holder's name in `LICENSE` and in commit
  authorship is fine, and nothing else about any person is. No email addresses
  (other than the GitHub noreply address), phone numbers, postal addresses,
  device names, home-directory paths (the user's home folder and `.claude` folders), or details about
  other real people.
- **Secrets:** no `.p8` keys, provisioning profiles, certificates, API keys or
  tokens, in the tree or in history.
- **History:** a rewrite is the only way to remove something already
  committed, and it needs the project owner's explicit approval first.

The check in `scripts/public-check.sh` runs in two places. Each clone enables
the pre-commit hook once with `git config core.hooksPath .githooks`. The GitHub
Actions workflow `.github/workflows/public-check.yml` runs the check and the
test suite on every push and pull request. The check needs the repo secret
`BANNED_TERMS` set to the contents of `scripts/banned-terms.local`. Without that
secret the workflow fails on purpose.

## Project overview

**initiative** is a personal iOS app built with SwiftUI, targeting iOS 17+. It's a single-window app with automatic code signing enabled. The home-screen name is **"Instant Initiative"** (`INFOPLIST_KEY_CFBundleDisplayName` in `project.yml`) — the repo, Xcode project, module, scheme, and bundle id all stay `initiative`; only the user-facing name changed.

## Development workflow

- **Phone first for redeploys.** The physical device is the preferred one
  for development. Redeploy to it after each completed change, using the
  device commands under "Looking at UI changes". The simulator is for quick
  checks while iterating.
- **One commit per completed change.** Commit each change as it finishes, not
  in one batch at the end. Put the tests for that change in the same commit
  when they make sense. Run `scripts/public-check.sh` before each commit.
- **Never push without the owner's go-ahead.** Commit locally when a change is
  done, then wait. A push to `main` starts a beta build upload, and a push
  of any kind is outward-facing, so only push when the owner says to, for that
  specific push.
- **Prune redundant tests.** When a test repeats what another test already
  covers, remove or merge it, in its own commit. Clean up a few at a time as
  you go, not in a separate big pass.

## Development commands

**Open project in Xcode**
```bash
open initiative.xcodeproj
```

**Build & run on a connected device**
- Select your device as the target device (top-left device selector in Xcode)
- Press ⌘R to build and run
- First run prompts for Apple ID code signing

**Add new Swift file**
XcodeGen automatically discovers all `.swift` files under `initiative/`, recursively (see Project structure below for where things live). Add a new `.swift` file in the appropriate subfolder, then regenerate the project:
```bash
xcodegen generate
```

**Preview a view during development**
SwiftUI Preview is the standard way to iterate on UI. Every view should have a `#Preview` block:
```swift
#Preview {
    MyView()
}
```
Open the Canvas (⌥⌘↩) to see live previews while editing.

## Project structure

Grouped by feature/layer, not flat — `project.yml`'s source glob is
`initiative/**/*.swift` (recursive), so XcodeGen picks up any subfolder
automatically; just put a new file in the right group and regenerate.

```
initiative/
├── App/              # initiativeApp.swift (@main), RootView.swift (nav root, owns
│                        the shared CombatSession/SessionStore/PresetStore/EncounterStore)
├── Models/           # One file per type: Combatant, Effect (+ EffectKind/DurationType),
│                        DeathSaves, LimitedUse (countable resources like Legendary
│                        Actions), TurnPrompt, LogEntry (+ HPOperation),
│                        CombatSession — plus their tests
├── Stores/           # SessionStore/PresetStore/EncounterStore (JSON-file persistence),
│                        DefaultContent.swift (the starter creature roster + encounters),
│                        (installed on every launch; built-ins are read-only) + tests
├── Views/
│   ├── Combat/        # ContentView (roster; tapping a row pushes to
│   │                     CombatantDetailView — inline in-row disclosure was tried
│   │                     twice and reverted, see SPEC.md "Declined": List animates
│   │                     a row's own height change no matter what, causing the
│   │                     row's own text to visibly slide/fly), CombatantDetailView
│   │                     (identity, health, tap-to-apply effects grid, Actions
│   │                     card), HealthControlRow (one-line current/max +
│   │                     damage/heal/temp/increase-max buttons — the piece
│   │                     CombatantDetailView builds its Health card from),
│   │                     LogView, AddCombatantSheet,
│   │                     EffectEditorView (duration config for one effect),
│   │                     LimitedUseEditorView (name + count for one resource),
│   │                     RoundEffectsView (effects owned by the fight), TurnPromptView
│   ├── MainMenu/       # MainMenuView
│   ├── Presets/        # PresetListView (Main Menu -> Creatures)
│   ├── Encounters/      # EncounterListView (+ its nested Edit/Add sheets)
│   ├── Sessions/       # SessionListView (Main Menu -> Load Session)
│   └── Settings/        # AppearanceView (Main Menu -> Appearance, theme picker)
├── Common/            # Theme.swift (the token vocabulary: color/spacing/radius/type),
│                        ThemePalette.swift (every palette's actual values),
│                        ThemeController.swift (which one is selected + persistence),
│                        ViewExtensions.swift (the shared view modifiers built on them),
│                        ListSections.swift + SearchBar.swift (how the Creatures
│                        and Encounters libraries are searched and sectioned),
│                        Conditions.swift, StatusBand.swift, FlowLayout.swift,
│                        SelectAllTextField.swift — shared across screens
├── Assets.xcassets/   # Images, colors, app icon
project.yml            # XcodeGen configuration (regenerates .xcodeproj)
.gitignore              # Excludes Xcode build artifacts, .DS_Store, etc.
```

## Architecture

**App entry point** (`App/initiativeApp.swift`):
- Uses `@main` macro to bootstrap the app
- Defines a `WindowGroup` scene containing `RootView`

**View hierarchy**:
- `RootView` (`App/`) is the navigation root — owns the app's shared state
  (session, stores) and the `NavigationStack`/`Route` routing
- `ContentView` (`Views/Combat/`) is the main combat screen
- Add new screens/views as separate `.swift` files under the matching
  `Views/<feature>/` subfolder (or a new one, for a new feature area)
- Use navigation containers (NavigationStack, TabView, etc.) for multi-screen navigation

**Styling & Colors**:
- **Everything visual comes from tokens in `Common/Theme.swift`** — color,
  `Theme.Spacing` (4pt scale), `Theme.Radius`, `Theme.Typography`. No literal
  padding numbers, corner radii, `Color(red:...)`, or `.font(.headline)` in a
  view; if a value is missing, add a token rather than a one-off. (Direction
  changed from an earlier "native iOS colors, custom theme only selectively"
  stance — that's no longer current.)
- **Reach for the shared modifiers in `Common/ViewExtensions.swift` first**:
  `themedScreen()` (full-screen backdrop), `CardRowButtonStyle(isHighlighted:)`
  (a `ButtonStyle` — apply as `.buttonStyle(CardRowButtonStyle())` on every
  tappable row's `Button`; it's the card look *and* press feedback together,
  since a plain modifier chained onto a `Button` sits outside the button's
  own label and never sees `isPressed`) + `cardRowLayout()` (every list row
  in the app), `sectionCard()` (a group of controls on a detail screen),
  `fieldStyle(width:)` (text input chrome), `Text.sectionLabel()` (tracked
  caps field label), `Text.cardHeading()` (serif card title),
  `appSearchable(text:prompt:isVisible:)` (`Common/SearchBar.swift` — the
  system's own `.searchable`, kept expanded as a text field, not minimized
  to an icon; not a hand-built bar), and `selfSizingSheet()` (sizes a sheet to
  its own content height instead of a fixed `.presentationDetents` fraction
  — used by small popups like `TurnPromptView` and `LimitedUseEditorView`).
  These exist because each was previously copy-pasted per screen and
  drifted apart.
- **The Creatures and Encounters screens are deliberately the same screen twice**
  — both are a saved library mixing built-in and user-made entries, so both get
  search (`appSearchable`) and a Yours-above-Included split from the shared
  `ListSections`. Change one and change the other; the matching and splitting
  live outside the views precisely so they can be tested. New Session (a third,
  simpler picker) reuses both the same way.
- **A `Section`'s title goes in its content, never its `header:` slot** — a
  `List` in `.plain` style pins whatever's in that slot so it floats and
  trails the scroll instead of moving with its own rows. Every "Yours"/
  "Included"-style label in the app (Creatures, Encounters, New Session,
  Appearance) is a plain `Text` row placed first inside the section instead.
- **The palette's rules, not just its values** — `Theme`'s doc comment is the
  authority, but in short: surfaces come from the elevation ladder
  (`background` → `surface` → `surfaceRaised`) rather than from borders, borders
  are hairline (`Theme.hairline`), and **`Theme.accent` marks at most one thing
  per screen**. Anything else that wants to stand out uses a status/category
  color.
- **Colors are themeable; the structure is not.** The values live in
  `ThemePalette` (nine of them, see `ThemeIdentifier`), `ThemeController` owns the
  selection, and `Theme`'s color accessors forward to it. **Never name a palette
  in a view** — say `Theme.surface`; SwiftUI re-renders on theme change because
  `ThemeController` is `@Observable` and observation tracking follows reads
  through static accessors. Adding a token means adding it to *every* palette
  (there are no defaulted fields, on purpose). Anything UIKit-side has to be
  re-applied by hand on change — see `Theme.applyNavigationBarAppearance()`,
  which also walks live windows because `UINavigationBar.appearance()` only
  affects bars created after it's set.
- **`ThemePaletteTests` enforces the design rules across every palette** —
  monotonic, perceptible elevation ladder; WCAG contrast for each text level on
  each surface; `accentForeground` legible on `accent`; declared `colorScheme`
  matching how the palette paints; nothing within 0.3 RGB of the accent. Run it
  after touching any color: it has already caught collisions that looked fine by
  eye.
- Prefer native system *components* (`Form`/`Section`, `List`,
  `ContentUnavailableView`, native swipe actions/confirmation dialogs) over
  hand-rolled containers — that part hasn't changed — but their *colors* must
  come from `Theme`, not system defaults. A `Form`/`List` is white by default;
  pair it with `.scrollContentBackground(.hidden)` + `themedScreen()` (see
  `ContentView.swift`) so it doesn't stand out as unthemed. The navigation bar
  is the exception that can't be done in SwiftUI at all — it's set once via
  `Theme.applyNavigationBarAppearance()` from `RootView.init`.

**Default content** (`Stores/DefaultContent.swift`) is **read-only and
permanent**. Built-ins can't be deleted, renamed, or edited — rows offer
Clone instead of Delete, the edit sheets open disabled with a Clone
action, and `PresetStore.upsert` refuses to touch a built-in (otherwise adding a
combatant named "Goblin" rewrites the built-in's stats). `installDefaults()` runs
on every launch and installs anything missing; adding to the table is all that's
needed for it to reach existing installs — do *not* reintroduce "seed only if the
store is empty", which is what prevented that. A preset the user holds under a
built-in's name is never overwritten. Encounters name creatures rather than
restating stats; keep it that way and `DefaultContentTests` will catch a typo'd
name.

- Consult the `ios-hig` skill before building new
  screens — practical Apple HIG checklist for this app.

## Important notes

**XcodeGen workflow**:
The `.xcodeproj` is *generated* from `project.yml`, not hand-edited. Always modify `project.yml` and regenerate:
```bash
xcodegen generate
```
This keeps the project structure reproducible and diffable (the generated `.pbxproj` is large XML, so diffs are hard to read).

**Code organization**:
- One view per file (standard SwiftUI convention)
- Keep view files focused on a single screen or reusable component
- Use the `Preview` macro for all views

**Dependencies**:
- Currently no external packages; SwiftUI is built-in
- If you add a package dependency, add it to `project.yml` under the target's `dependencies` section

## Colour and colour-blindness

Every theme must work for people with colour-vision deficiency. The palettes
are built on the Okabe-Ito set, which was designed to stay distinct under the
common types: protanopia and deuteranopia (red-green) and tritanopia (blue-yellow).

- **Good is blue, bad is orange or vermillion, warning is yellow, info is
  bluish green or teal.** Never pair red with green for status, and never pair
  blue with purple or with green for two states that matter together.
- **Colour is never the only cue.** A status also shows in text, weight, an
  icon, or position. A changed number is bold and coloured, and the detail
  screen shows the amount; a band is named in words ("Medium AC").
- **Check every palette under simulated deficiency** before it ships: protanopia,
  deuteranopia, tritanopia and achromatopsia. Chrome DevTools (Rendering tab)
  and Firefox's Accessibility Inspector can simulate these on a running screen.
  `ThemePaletteTests` checks contrast, the elevation ladder and accent clearance
  for every palette; it does not simulate deficiency, so the check above is still
  needed for any palette change.
- **Keep the status colours apart by lightness as well as hue**, so they still
  separate in greyscale and under low vision.
- **Colour-blind themes** are `colorblindDark` and `colorblindLight`. They use the
  same status roles as the others, with the Okabe-Ito pairs above.

## Verifying on the phone: test scenarios

Every change that the owner should look at ends with a **test scenario** they can
open on the phone. The scenario is a test-only combat, built with the same session
methods the unit tests use, so the owner sees the rule working on the real screen.

- **Where:** `initiative/Debug/TestCombats.swift`, behind `#if DEBUG`. Each scenario
  is a static function, listed in `TestCombats.scenarios` under the same name. The
  file is excluded from Release builds, so beta and store builds never contain it.
- **Naming:** name the scenario after what it verifies (`deadCreatureIsSkipped`,
  `dyingWithTally`), not after the screen. The unit tests use the same fixtures.
- **Opening it:** the debug main menu has a **Test Scenarios** entry at the bottom.
  Pick the scenario and the combat screen opens. From a terminal, a debug build also
  opens one at launch with `-scenario <name>`.
- **After each feature:** build the debug app for the phone, install it, and launch
  the scenario, then tell the owner what to check, for example "Next from Alpha should
  go to Omega". Give the exact steps. Use the device commands under "Looking at UI
  changes" above.
- **Checking the screen:** the owner can see the phone, not the agent. Ask the owner
  what they see, and do not claim a visual result that has not been confirmed.

## Testing

The `initiativeTests` target (XCTest) covers `Models/Models.swift` and the `Stores/`
files — turn order, reaction resets, effect expiration, and session persistence. Add
new test files ending in `*Tests.swift` anywhere under `initiative/` (conventionally
alongside the file they test, e.g. `Stores/PresetStoreTests.swift`); they're
auto-excluded from the app target and auto-included in the test target via
`project.yml`'s recursive include/exclude globs, no manual wiring needed.

**Every new piece of testable logic gets a test, and every bug fix gets a regression
test that fails without the fix and passes with it** — not just "does it build."
This applies to model/store logic (`CombatSession`, `SessionStore`) directly; there's
no UI test target, so keep SwiftUI view bodies as thin, trivial derivations of
already-tested model/store state (e.g. `if canResume { ... }` reading a tested
`SessionStore` method) rather than putting logic worth testing only in a view body.
Confirm the new/regression test actually exercises the bug: run it against the
pre-fix code first if there's any doubt it would catch the issue.

**Always run tests after changing `Models.swift` or any view logic, before considering
a change done.** Run from the CLI (faster feedback than opening Xcode, and avoids
device code-signing prompts):

```bash
xcodebuild test -scheme initiative -destination "platform=iOS Simulator,id=<UDID>"
```

Get a UDID from `xcrun simctl list devices available`. Prefer the `id=` form:
the `name=` form has been observed to fail with "Unable to find a
device matching the provided destination specifier" even when a simulator by
that exact name is listed as available.

**Looking at UI changes**: boot a simulator and drive it from the CLI rather
than guessing from code —

```bash
xcrun simctl boot <UDID>
xcodebuild build -scheme initiative -destination "platform=iOS Simulator,id=<UDID>"
xcrun simctl install <UDID> "$(find ~/Library/Developer/Xcode/DerivedData/initiative-*/Build/Products/Debug-iphonesimulator -maxdepth 1 -iname 'initiative.app')"
xcrun simctl launch <UDID> xyz.rudsvar.initiative
xcrun simctl io <UDID> screenshot shot.png
```

There is no way to *tap* from the CLI here (no `cliclick`/`idb`, and System
Events' `click at` fails against Simulator), so a screen behind navigation can't
be reached by scripting taps. To see one, seed state and reach it directly:
write a `SessionRecord` JSON into
`$(xcrun simctl get_app_container <UDID> xyz.rudsvar.initiative data)/Documents/SavedSessions/`
and set the last-active pointer with
`xcrun simctl spawn <UDID> defaults write xyz.rudsvar.initiative lastActiveSessionID "<uuid>"`,
then add a *temporary* launch-argument branch in `RootView` that pushes the
route you want. Delete that branch before committing — it must not ship.

**After significant changes, also build, install, and launch on a real device**
if one is connected — catches device-only issues (letterboxing, signing,
real-hardware behavior) that the simulator can't. Check connection first:

```bash
xcrun devicectl list devices
```

Then, with the device UDID from that output (`Identifier` column):

```bash
xcodebuild build -scheme initiative -destination "id=<device-UDID>"
xcrun devicectl device install app --device <device-UDID> \
  "$(find ~/Library/Developer/Xcode/DerivedData/initiative-*/Build/Products/Debug-iphoneos -maxdepth 1 -iname 'initiative.app')"
xcrun devicectl device process launch --device <device-UDID> xyz.rudsvar.initiative
```

This installs and foregrounds the app on the phone with no manual Xcode steps —
useful for catching things like the Info.plist letterboxing bug that only showed
up on-device. Skip this for trivial/text-only changes; reserve it for changes that
touch layout, signing/Info.plist, persistence, or navigation.

The signing team is not in git. `Config/Signing.xcconfig` (committed) includes
`Config/Signing.local.xcconfig` (git-ignored), which sets `DEVELOPMENT_TEAM` to the
team's Apple Developer team ID. On a new machine, copy
`Config/Signing.local.xcconfig.example` to `Signing.local.xcconfig` and set the
ID. Without it, simulator builds still work, but a device build fails with
"requires a development team". Do not move the ID back into `project.yml`. If the
team changes, edit only the local file.

**Adding a field to a saved type** (`Combatant`, `Effect`, `CreaturePreset`):
Swift's *synthesized* `Codable` does **not** fall back to a property's declared
default when the key is missing, so a new non-optional field silently breaks
every previously saved session. Those three types therefore have hand-written
`init(from:)` decoders that use `decodeIfPresent(...) ?? default`. Keep it that
way, and add a literal-JSON case to `CodableCompatibilityTests` for anything new.

## Session persistence compatibility

**Not yet published — no compatibility constraint currently applies.** Once this app
ships to a device as a "real" install the user relies on day-to-day, `SessionRecord`
(in `SessionStore.swift`) and its `Codable` encoding become a durable on-disk format:
saved sessions must keep decoding across app updates, or a person's in-progress combat
gets silently wiped. At that point: only add fields with defaults (never remove/rename
existing `CodingKeys` without a migration), and treat `DurationType`'s manual `Codable`
implementation as equally frozen. Revisit this note and make it a hard rule once the
app is actually installed/published somewhere real.

## Session model (no explicit save)

There is no "Save Session" button/dialog — every `CombatSession` has a stable `id`
(assigned at `init`/`reset()`) and an auto-generated `name` (date/time-based). Autosave
just writes `session.makeRecord()` to `SessionStore` under that same `id`, so repeated
autosaves overwrite one file rather than piling up duplicates — the record on disk
*is* the session, named automatically, no user action required. `SessionStore` tracks
which session id was last active (UserDefaults) so "Resume" on the main menu knows
what to reload. Deleting a saved session (swipe + confirm on the Load Session screen)
also clears the last-active pointer if it pointed at the deleted one.

## Info.plist / launch screen (important gotcha)

This target uses `GENERATE_INFOPLIST_FILE: YES`, which means **Xcode builds Info.plist
purely from `INFOPLIST_KEY_*` build settings** — a top-level `infoPlist:` dict in
`project.yml` (nested keys like `UILaunchScreen`, `UIApplicationSceneManifest`) is
silently ignored and never reaches the built app. This previously caused the app to run
letterboxed (black bars top/bottom) on a real device since no launch screen config
existed at all. Use `INFOPLIST_KEY_UILaunchScreen_Generation: YES` and
`INFOPLIST_KEY_UIApplicationSceneManifest_Generation: YES` instead (see `project.yml`).
After any Info.plist-related change, verify the key actually landed —
`plutil -p <built .app>/Info.plist` — rather than trusting `xcodegen generate` output
alone; a clean build can silently drop keys that look correct in `project.yml`.
