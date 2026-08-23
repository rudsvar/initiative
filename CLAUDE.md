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
XcodeGen automatically discovers all `.swift` files in the `initiative/` directory. Add a new `.swift` file there, then regenerate the project:
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

```
initiative/
├── initiativeApp.swift        # @main entry point, defines WindowGroup scene
├── ContentView.swift          # Main root view
├── Assets.xcassets/           # Images, colors, app icon
project.yml                    # XcodeGen configuration (regenerates .xcodeproj)
.gitignore                     # Excludes Xcode build artifacts, .DS_Store, etc.
```

## Architecture

**App entry point** (`initiativeApp.swift`):
- Uses `@main` macro to bootstrap the app
- Defines a `WindowGroup` scene containing the root view

**View hierarchy**:
- `ContentView` is the root view
- Add new screens/views as separate `.swift` files in the `initiative/` directory
- Use navigation containers (NavigationStack, TabView, etc.) for multi-screen navigation

**Styling & Colors**:
- Use SwiftUI's built-in semantic colors (`.tint`, `.background`, etc.) for theme consistency
- Colors can be defined in Assets.xcassets for app-wide theming

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

The `initiativeTests` target (XCTest) covers `Models.swift` — turn order, reaction
resets, and effect expiration logic. Add new test files ending in `*Tests.swift` in
`initiative/`; they're auto-excluded from the app target and auto-included in the
test target via `project.yml`'s include/exclude globs, no manual wiring needed.

**Always run tests after changing `Models.swift` or any view logic, before considering
a change done.** Run from the CLI (faster feedback than opening Xcode, and avoids
device code-signing prompts):

```bash
xcodebuild test -scheme initiative -destination "platform=iOS Simulator,name=phone 16 Pro"
```

If that destination isn't available, list available simulators with
`xcrun simctl list devices available` and substitute one, or use
`-destination "platform=iOS Simulator,id=<UDID>"`.

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
saved sessions and the autosave slot must keep decoding across app updates, or a
person's in-progress combat gets silently wiped. At that point: only add fields with
defaults (never remove/rename existing `CodingKeys` without a migration), and treat
`DurationType`'s manual `Codable` implementation as equally frozen. Revisit this note
and make it a hard rule once the app is actually installed/published somewhere real.
