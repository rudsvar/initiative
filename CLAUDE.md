# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

**initiative** is a personal iOS app built with SwiftUI, targeting iOS 17+. It's a single-window app with automatic code signing enabled.

## Development commands

**Open project in Xcode**
```bash
open initiative.xcodeproj
```

**Build & run on connected phone**
- Select your phone as the target device (top-left device selector in Xcode)
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
├── Models/           # One file per type: Combatant, Effect (+ DurationType), LogEntry
│                        (+ HPOperation), CombatSession — plus ModelsTests.swift and
│                        CodableCompatibilityTests.swift
├── Stores/           # SessionStore/PresetStore/EncounterStore (JSON-file persistence),
│                        DefaultContent.swift (the starter creature roster + encounters),
│                        DefaultInstallLedger.swift (how defaults stay additive) + tests
├── Views/
│   ├── Combat/        # ContentView, CombatantDetailView, LogView, AddCombatantSheet, AddEffectView
│   ├── MainMenu/       # MainMenuView
│   ├── Presets/        # PresetListView (Main Menu -> Creatures)
│   ├── Encounters/      # EncounterListView (+ its nested Edit/Add sheets)
│   ├── Sessions/       # SessionListView (Main Menu -> Load Session)
│   └── Settings/        # AppearanceView (Main Menu -> Appearance, theme picker)
├── Common/            # Theme.swift (the token vocabulary: color/spacing/radius/type),
│                        ThemePalette.swift (every palette's actual values),
│                        ThemeController.swift (which one is selected + persistence),
│                        ViewExtensions.swift (the shared view modifiers built on them),
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
  `themedScreen()` (full-screen backdrop), `cardRowStyle(isHighlighted:)` +
  `cardRowLayout()` (every list row in the app), `sectionCard()` (a group of
  controls on a detail screen), `fieldStyle(width:)` (text input chrome),
  `Text.sectionLabel()` (tracked caps field label) and `Text.cardHeading()`
  (serif card title). These exist because each was previously copy-pasted per
  screen and drifted apart.
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
**Default content** (`Stores/DefaultContent.swift`) is **additive, never
all-or-nothing**: `installNewDefaults()` runs on every launch and installs
anything the `DefaultInstallLedger` has never offered before. Adding a creature
or encounter to the table is all that's needed for it to reach existing
installs — do *not* reintroduce "seed only if the store is empty", which is what
prevented that. Deletions are respected (only the explicit "Restore Defaults"
menu item overrides one), and a preset the user has edited is never overwritten
by its default. Encounters name creatures rather than restating stats; keep it
that way and `DefaultContentTests` will catch a typo'd name.

- Consult the `ios-hig` skill (`<agent-config>/skills/ios-hig/SKILL.md`) before building new
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
the `name=phone 16 Pro` form has been observed to fail with "Unable to find a
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

**After significant changes, also build, install, and launch on the real phone**
("Umbra") if it's connected — catches device-only issues (letterboxing, signing,
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

`DEVELOPMENT_TEAM` in `project.yml` is set to `YOUR_TEAM_ID` (Rudi Svartveit's personal
Apple Developer team). Do not blank this out or `xcodegen generate`
will silently strip signing on every regen and break `xcodebuild build -destination
generic/platform=iOS` (device build) with "requires a development team". If Xcode ever
reassigns a different team ID, check `~/Library/Preferences/com.apple.dt.Xcode.plist`
(`IDEProvisioningTeamByIdentifier`) or a device build's `project.pbxproj` for the
current value and update `project.yml` to match — don't leave it blank.

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
