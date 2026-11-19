# Release checklist

The app is in beta: CI uploads every push to `main` for beta testing. This file
holds what is still open before a public release in the Apple store, and the steps
for doing it. Setup and CI are in [SETUP.md](SETUP.md).

Status: beta only. Public release is not planned yet.

## Blocking items

- [ ] **Real app icon.** The icon in `initiative/Assets.xcassets/AppIcon.appiconset`
  is a placeholder (a plain dark-blue square). Replace `AppIcon-1024.png` with an
  opaque 1024×1024 PNG with no transparency and no pre-rounded corners. The
  system rounds it. Check it at small sizes, in light and dark modes, and on the
  home screen.
- [ ] **Final name.** The home-screen name is `Instant Initiative` (set in
  `project.yml`), but a shorter name is wanted. The owner picks it. Then check it
  is free in the store, set `INFOPLIST_KEY_CFBundleDisplayName`, update the store
  listing name, and update the name in `README.md` and `CLAUDE.md`.
- [ ] **Store listing text**, written in the owner's voice and checked against the
  rules in `CLAUDE.md` (no trademark names):
  - Name (up to 30 characters) and subtitle (up to 30 characters).
  - Description and "What's New" for version 1.0.
  - Keywords (up to 100 characters, comma-separated, no spaces after commas).
  - Category (suggested: Utilities or Reference; check the store guidelines).
  - Copyright line.
- [ ] **Privacy policy URL.** Required by the store. The app collects nothing, so
  the policy says so: no accounts, analytics, advertising or tracking, and all
  data stays on the device. Host it on a page the owner controls.
- [ ] **Support URL.** A page or an email contact the owner is happy to publish.
- [ ] **Privacy questionnaire.** Answer "Data Not Collected" if that stays true.
  Recheck it after every feature change that adds network use or storage.
- [ ] **Age rating questionnaire.** Answer for a fictional combat tracker with no
  real-world violence depicted. Expect the lowest rating.
- [ ] **Screenshots.** Required sizes for the current largest supported phone and the
  current smallest one the app supports. Take them on the simulator, with sample
  encounters loaded. Show the combat screen, the creatures list and one detail
  screen. Do not show anything personal in the sample data.
- [ ] **Credits.** `README.md` and `NOTICE` carry the SRD 5.2.1 attribution. Check
  that the store description does not claim the content is original where it is
  not.
- [ ] **Export compliance.** Already set (`ITSAppUsesNonExemptEncryption` is `NO`).
  Confirm the store shows no question during upload.
- [ ] **Review notes.** Short note for the reviewer: what the app does, that no
  account or network is needed, and how to start a combat.
- [ ] **Pricing and availability.** Free. Choose the countries.

## Before submitting a build

- [ ] Work through the device check in [CLAUDE.md](../CLAUDE.md) on a real phone,
  including the Creatures stat columns, a saved session after relaunch, and the
  home-screen name after a fresh install.
- [ ] Run the full test suite and `scripts/public-check.sh`.
- [ ] Set `MARKETING_VERSION` in `project.yml` for the release (`1.0.0` for the
  first; after that, as in "Versioning" in `CLAUDE.md`). Build numbers come from
  CI.
- [ ] Update `CHANGELOG.md`: move "Unreleased" under the version number, using the
  date of release.
- [ ] Wait for the beta upload of the release commit to finish, and check it
  processed without warnings. Then pick that build for the version in the store
  console.
- [ ] Ask the owner to try the release build from the beta program first, and to
  confirm it.

## Submitting

1. In the store console, create the app record with bundle ID
   `xyz.rudsvar.initiative` (only if it does not exist yet).
2. Create a new version, enter the listing text and screenshots from above.
3. Select the processed build. Fill in the review notes, the privacy and age
   answers, and the support and privacy URLs.
4. Submit for review. Review can take a day or more. A rejection is returned with
   a reason; fix it, upload a new build by pushing to `main`, and resubmit.
5. After approval, choose the release date (manual or automatic), then release.

## After release

- Tag the release commit (`git tag v<version> <sha>`, then push the tag).
- Keep beta uploads going for the next version on `main`, but set the next
  `MARKETING_VERSION` only when that version starts.
- Review this file and fix any step that did not match what happened.
