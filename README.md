# initiative

A SwiftUI iOS app for personal use.

## Development

### Open in Xcode
```bash
open initiative.xcodeproj
```

### Build & Run
- Select your phone as the target device
- Press ⌘R to build and run on device
- Xcode will prompt for code signing with your Apple ID on first run

### Project Structure
- `initiative/` — Swift source files
  - `initiativeApp.swift` — App entry point
  - `ContentView.swift` — Main UI
  - `Assets.xcassets/` — Images and assets
- `project.yml` — XcodeGen project definition (regenerates `initiative.xcodeproj`)

### Modifying the Project
Edit `project.yml` and regenerate:
```bash
xcodegen generate
```

## Requirements
- Xcode 15+ (supports iOS 17 APIs)
- phone with iOS 17+
