# Initiative

A free, ad-free initiative tracker for tabletop RPG combat, for iOS.

## What it does

- Tracks turn order, hit points, conditions, and effects for a combat.
- Keeps saved creatures and encounters, and saves the current fight automatically.
- Runs offline. It is designed to collect nothing: no accounts, analytics or ads.

## Credits

Some built-in creatures use stat blocks from the System Reference Document 5.2.1,
licensed under CC BY 4.0. See [NOTICE](NOTICE).

## Status

Work in progress. The app is not released yet, and the
final name is not decided. Building it needs an Apple Developer account, which
is still pending.

## AI use

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/0rwx-AI-X-dark.png">
  <img src="assets/0rwx-AI-X-light.png" alt="0rwx AI-X logo" width="100">
</picture>

Most of the code was written with an AI coding assistant. The project is
labelled **AI MADE (X)** in the [0rwx framework](https://0rwx.com/). The logo is
CC0 (public domain) from
[NamtaoProductions/0rwx.com](https://github.com/NamtaoProductions/0rwx.com/).

## Build

Requires Xcode and iOS 17 or later.

```sh
xcodegen generate
open initiative.xcodeproj
```

The `.xcodeproj` is generated from `project.yml`; edit that file, not the project.

## Licence

MIT. See [LICENSE](LICENSE).
