# Setup

How to build, sign, test and beta-upload the app. Read this first on a new
machine or when setting up CI again. Release steps are in [RELEASE.md](RELEASE.md).

## What you need

- A Mac with a current Xcode (the CI runner uses Xcode on macOS 26).
- An Apple Developer account, for signing and for beta uploads.
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`.

## Build from source

```sh
git clone https://github.com/rudsvar/initiative.git
cd initiative
git config core.hooksPath .githooks   # enables the public-repo check on commit
xcodegen generate
open initiative.xcodeproj
```

`initiative.xcodeproj` is generated from `project.yml`. Edit `project.yml` and run
`xcodegen generate` again. Do not hand-edit the project.

Simulator builds work without a team. To run on a phone, set your team:

```sh
cp Config/Signing.local.xcconfig.example Config/Signing.local.xcconfig
```

Then put your 10-character team ID (from the developer membership page) in
`Config/Signing.local.xcconfig`. That file is git-ignored. Do not put the team ID
in `project.yml` or any other tracked file.

Run the tests from the command line:

```sh
xcrun simctl list devices available            # pick a UDID
xcodebuild test -scheme initiative -destination "platform=iOS Simulator,id=<UDID>"
```

## Identifiers

- Bundle ID: `xyz.rudsvar.initiative`. It is registered in the developer portal.
  Changing it creates a new app and loses on-device data, so keep it.
- Home-screen name: `INFOPLIST_KEY_CFBundleDisplayName` in `project.yml`. Changing
  it does not affect signing.
- Version: `MARKETING_VERSION` in `project.yml` (the version users see). Build
  numbers are not in the repo: CI sets them from the run number on every upload.
- Export compliance: `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption` is `NO`, because
  the app only uses the system's HTTPS.

## Continuous integration

Two workflows run on every push to `main`:

| Workflow | File | What it does |
| --- | --- | --- |
| Public repo check | `.github/workflows/public-check.yml` | Runs `scripts/public-check.sh`, then the test suite. |
| Beta upload | `.github/workflows/testflight.yml` | After the check passes on `main`, archives the Release build and uploads it for beta testing. Can also be started by hand (`workflow_dispatch`). |

Pushes in quick succession start one upload each. Batch related commits into one
push when you can.

### Repository secrets

Set these under the repository's Settings → Secrets and variables → Actions.

| Secret | Used by | Value |
| --- | --- | --- |
| `BANNED_TERMS` | Public repo check | Contents of `scripts/banned-terms.local` (git-ignored, keep your own copy). Without it the check fails on purpose. |
| `ASC_KEY_ID` | Beta upload | Key ID of the Apple API key. |
| `ASC_ISSUER_ID` | Beta upload | Issuer ID of the same key. |
| `ASC_KEY_P8` | Beta upload | Full text of the `.p8` key file. |
| `APPLE_TEAM_ID` | Beta upload | Your 10-character team ID. |

If any of the last four is missing, the beta upload skips with a notice instead of
failing.

### Apple API key

Create it in the developer portal under Users and Access → Integrations (team keys for the API).

- Use the **Admin** role. An App Manager key failed cloud signing with "Cloud
  signing permission error" and "No profiles for the bundle ID".
- Make one key per app, and name it after the app, so a key can be revoked alone.
- The `.p8` file can be downloaded once only. Store it in a password manager before
  pasting it into `ASC_KEY_P8`.

### Public-repo check

`scripts/public-check.sh` fails on trademark names, personal details, home-folder
paths and secret-looking files, in the tree and in every commit. The list of
trademark names is in `scripts/banned-terms.local`, which is git-ignored, so the
list itself never reaches the repo. Each line is one extended regex. Write
generic wording in comments, file names and commit messages (for example "beta"
for the beta program and "store" for the Apple store).

Run it before each push: `scripts/public-check.sh`.

## Working notes

- Redeploy to a phone after each finished change, with `xcrun devicectl`. The
  commands are in [CLAUDE.md](../CLAUDE.md#development-commands).
- New `.swift` files are picked up by XcodeGen automatically after
  `xcodegen generate`.
- Assets: the app icon lives in `initiative/Assets.xcassets/AppIcon.appiconset`.
  The current icon is a placeholder (see the first item in [RELEASE.md](RELEASE.md)).
- XcodeGen only builds the icon when the asset catalog is listed under the
  target's `sources:`, not `resources:`, and the target sets
  `ASSETCATALOG_COMPILER_APPICON_NAME`. Both are set in `project.yml`.
- With `GENERATE_INFOPLIST_FILE: YES`, Info.plist values come only from
  `INFOPLIST_KEY_*` settings. A nested `infoPlist:` block is ignored. Check a built
  app with `plutil -p <App>.app/Info.plist`.
- The beta upload uses `automatic` signing with the API key, so the runner can
  create the profiles itself.
