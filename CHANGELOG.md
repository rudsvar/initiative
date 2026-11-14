# Changelog

All notable changes to this project are documented here, newest first.

## [Unreleased]

### Changed — roll prompt answers are always "Success"/"Failure"

- `TurnPrompt.successLabel`/`failureLabel` used to vary by subject ("Made
  it"/"Not yet" for effects, "Held it"/"Lost it" for concentration, "Success"/
  "Failure" for death saves). Now always "Success"/"Failure" — the prompt's
  own title already says what's being rolled for, so the different phrasing
  per subject added variety without adding information.

### Changed — removed the "5–6 on a d6" example from the roll-hint field

- The custom round-effect editor's "what to roll" field showed "e.g. 5–6 on
  a d6" as placeholder text — an actual roll threshold, even shown only as
  an example, isn't something this app should ever suggest. What's rolled
  and what counts as success depends entirely on the rules in play and the
  specific ability; the app doesn't know either and shouldn't imply a
  default. Placeholder is now just "What to roll (optional)"

### Changed — one roll prompt at a time

- **`TurnPromptView` shows one owed roll at a time instead of stacking all of
  them in the sheet at once.** With several owed together (a couple of death
  saves plus a recharge, say) the stacked version had no `ScrollView`, so
  `selfSizingSheet()` measured a height taller than the screen with no way
  to reach what didn't fit — not scrollable, and dragging the sheet couldn't
  expand it past its own fixed detent either. Now it just shows the next
  unanswered prompt ("Roll 2 of 3") and advances automatically as each is
  answered, which also keeps the sheet's height bounded no matter how many
  are owed
- **The roll prompt sheet is dismissible again** (swipe away), and doing so
  just clears it without advancing — nothing is applied until every prompt
  has an answer, so backing out mid-prompt can't half-advance the turn;
  worst case the same prompts reappear next time you try to advance
- **The roll prompt now uses the system's own sheet material
  (`.presentationBackground(.regularMaterial)`) instead of a custom `Theme`
  fill.** A darker `Theme.background` wrapped around a lighter
  `Theme.surface` card was the first fix tried — it removed the mismatched
  seam, but a flat custom color still looked out of place against sheet
  chrome the system itself draws (drag indicator, corner radius, dimmed
  backdrop), which doesn't know about this app's palette. `.regularMaterial`
  is what native sheets actually use and adapts to light/dark automatically,
  so this one popup now reads as a normal iOS sheet rather than a themed
  card wearing sheet chrome — a deliberate, scoped exception to "everything
  visual comes from `Theme`," not a change to that rule generally

### Changed — combined turn bar, encounter search fixed, keyboard bug fixed

- **The combat screen's bottom bar is four separate circular glass buttons**
  (Previous, Log, View, Next — arrows on the ends, View/Log filling the
  middle two slots), not the single fused pill tried earlier this
  round — the fused version read as one odd blob rather than distinct
  controls. Media-style icons (`backward.fill`/`forward.fill`), not chevrons,
  since stepping through turns is the same shape as transport controls. Log
  sits next to Previous and View next to Next, all four evenly spaced
- **View and Log are direct buttons in the bar**, not hidden behind a
  hamburger `Menu` that only ever held those two items — one tap instead of
  two for something reached for almost as often as Next itself
- **Previous is accent-colored when there's a turn to go back to**, not a
  flat gray regardless of state — dims to a tertiary gray only once disabled
- **The roster's initiative number is smaller** (27pt → 21pt) — it was
  crowding the row next to the name at the old size
- **Encounter search now matches if *any* typed word matches** (OR), not
  only when *every* word matches (AND) — typing "goblin troll" now finds an
  encounter containing either, the more useful default when a query is
  likely to name several different things you're looking for at once.
  Creature search is unchanged (AND still makes sense there — narrowing by
  more than one word about the *same* creature)
- **Fixed: the Limited Use editor's Stepper would overlap the Name field
  once the keyboard appeared, and the Add/Save button would stop
  responding.** `selfSizingSheet`'s height measurement was reacting to the
  keyboard's safe-area inset shrinking the space available to it, which fed
  back into a shrinking `presentationDetents` height, compressing the
  sheet's own layout — fixed by having that measurement ignore the keyboard
  safe area entirely, so the sheet's size stays stable regardless of it
- **Encounter search's placeholder text said "and" while the search itself
  used OR logic** — fixed the wording ("Search encounters or creatures") to
  match
- **Fixed: the search field's text did a visible tiny resize right as a
  screen appeared.** Pinning the search field's UIKit font explicitly (in
  `Theme.applyNavigationBarAppearance`) turned out not to be the whole
  story — the real cause was `appSearchable`'s `isVisible` flipping from
  false to true right after the first frame (Creatures/Encounters/New
  Session all started with an empty array, populated a moment later in
  `.onAppear`), which mounted `.searchable` for the first time on a *later*
  render instead of the first one; that cold mount is what animated in and
  read as a font resize. Fixed by loading each screen's data eagerly at
  `init` instead, so `.searchable` is present, correctly, from frame one

### Changed — native search, floating bottom bar, fixed tap targets

- **Search is now the system's own `.searchable` field**, not a hand-built
  bar — the custom one (tried in this same round of changes) read as too
  wide and too heavy next to how search actually looks on iOS 26. On iOS 26+
  it's paired with `.searchToolbarBehavior(.minimize)`, the same native
  glass-search pattern Notes/Files/Photos use. `appSearchable(text:prompt:
  isVisible:)` replaces `bottomSearchBar`; the custom `SearchBar` view and
  its `glassBar()` helper are gone. Creatures, Encounters, and (new) New
  Session all use it now — New Session had no search at all before
- **The combat screen's bottom bar floats over the roster** via
  `.safeAreaInset(edge: .bottom)` instead of sitting in a plain `VStack`
  next to the list — rows are now visible scrolling behind it instead of
  stopping dead above a hard-edged bar, matching the search field's
  floating treatment
- **List section headers ("Yours"/"Included", "For a dark room"/"For a lit
  room") no longer pin and follow the scroll.** `List` in `.plain` style
  pins whatever's in a `Section`'s `header:` slot; every screen using that
  slot (Creatures, Encounters, New Session, Appearance) had its label
  floating and trailing the scroll instead of moving with its own rows. Now
  the label is a plain row inside the section instead of its header, which
  scrolls normally
- **Chip and step buttons are now clickable across their whole visible
  area**, not just the icon+text inside them. `EffectChip`, `LimitedUseChip`,
  and the bottom bar's Previous/Options/Next buttons all sized their tap
  target to their label's intrinsic content while a `.frame(maxWidth:
  .infinity)` applied *outside* the button stretched only the layout slot
  around it — tapping the empty space a chip or a third of the bar visually
  fills out to did nothing. Fixed by moving `.frame(maxWidth: .infinity)` +
  `.contentShape(Rectangle())` inside each button's own label

### Changed — floating glass nav bars and search field (iOS 26+)

- **Navigation bars are transparent instead of opaque on iOS 26+**
  (`Theme.applyNavigationBarAppearance`), so the system's native floating
  Liquid Glass title bar shows through — list content is now visible
  scrolling up underneath it, the way title bars behave everywhere else on
  iOS 26. The custom opaque background this app had painted on every bar
  since before glass existed was single-handedly blocking that: it doesn't
  just make titles look flat, it visually hides the content that's already
  scrolling behind the bar regardless. Below iOS 26 the bar keeps its
  original opaque `Theme.backgroundLift` fill, unchanged
- (The bottom search field also got a floating-pill redesign in this round,
  since replaced by the system's own `.searchable` — see "native search,
  floating bottom bar, fixed tap targets" above.)

### Added — visible tap feedback; glass on nav buttons and search

- **Every tappable row now visibly dims/scales on press** — combatant,
  creature, encounter, session, and theme rows. Previously a plain `Button`
  with `.cardRowStyle()` chained on afterward had *no* press feedback at all
  inside a `List`: that chained modifier sits outside the button's own label,
  so the button's built-in press-dimming never touched it (and the combatant
  row's tap target was a fully hidden `NavigationLink` in the background,
  which had nothing visible to dim in the first place). New shared
  `CardRowButtonStyle` folds the same background/border/highlight look into
  a real `ButtonStyle` so `configuration.isPressed` can darken and slightly
  scale it. The combatant row's navigation was rebuilt on a proper `Button`
  + `Route.combatantDetail(UUID)` push instead of the hidden-link trick, so
  it gets the same feedback as every other row
- **Liquid Glass extended to the bottom search field** on Creatures/Encounters
  (`glassBar()`, a no-op below iOS 26 where the field keeps its existing flat
  `Theme.surfaceRaised` look) — the same floating-over-content case the combat
  screen's bottom bar already qualified for. The top nav bar's own icon
  buttons (back, add) turn out to need no code at all: a standard
  `ToolbarItem` button is automatically glass-styled by the system on iOS 26,
  and manually adding `.buttonStyle(.glass)` to one is redundant and can
  conflict — briefly added, then reverted once traced back to this project's
  own `ios-hig` skill, which already documents the rule.
  Glass stays deliberately restricted to the surfaces that skill calls out —
  not spread to every button in the app

### Changed — New Session splits encounters into Yours/Included

- **"New Session" now groups prepared encounters into "Yours" and
  "Included"** sections, same split (and same `ListSections.split` logic) the
  Encounters library itself uses — previously every encounter, built-in or
  custom, was listed together under one flat "From an Encounter" header, so
  a user's own encounters could get buried among the shipped ones

### Changed — Reaction/Concentration off the roster; compact one-line health

- **Reaction and Concentration are gone from the roster row** — the read-only
  status strip on each row shows only conditions/cooldowns now; Reaction and
  Concentration live on the combatant detail screen alongside everything else
- **Tapping a row still pushes to `CombatantDetailView`**, unchanged from
  before. Two in-place-disclosure designs were tried this round — a
  chevron-per-row unfold, and before that an auto-expanding current-combatant
  row — and both were reverted: `List` animates a row's own height change
  internally regardless of whether the app requests an animation, which made
  a row's own text visibly slide as it resized, with no reliable way found to
  suppress it (an explicit `.animation(value:)`, then a `disablesAnimations`
  transaction, were each tried and still glitched). A pushed screen has no
  row to resize, so the artifact can't occur there
- **Health collapses to one line**: current/max readout plus four small
  buttons (damage, heal, grant temp HP, increase max HP), each prompting for
  its amount via an inline alert instead of a persistent Amount field.
  Replaces the old three-row Current/Max/Temp layout on the detail screen
- **Current is bolded while temporary HP is active; Max is bolded once it's
  ever been raised** by Increase Max HP — shown both on the roster row and
  the detail screen, a quick visual flag for "this number isn't the base
  anymore" without adding another label. The roster row no longer also
  appends a "+8" suffix for the temp buffer — the bold already says it, and
  the exact amount is a tap away on the detail screen
- **The combatant's name is editable directly in the detail screen's top
  bar** (same select-all-on-focus field as the session name), so there's no
  separate Name field lower on the screen
- **Health/AC now right-align to a fixed column** across roster rows. The
  heart/shield icon trails the number rather than leading it, both pinned to
  the same fixed-width column, so the icons themselves line up vertically
  between rows regardless of how many digits the number before them has —
  putting the icon first only aligned the row's overall right edge, not the
  icon
- **Heart and shield icons are colored red/blue** (fixed per stat) instead of
  the same neutral gray as the number next to them — a quick "which stat is
  this" cue independent of the number's own color (which still reflects the
  health/AC band in player view)

### Added — Limited Use (Legendary Actions and the like)

- **`LimitedUse`: a named, countable resource** ("Legendary Actions", "3/day"),
  spent one tap at a time like `Reaction` but counting down instead of
  flipping a bool. Replaces "Once per encounter", which was really the same
  idea with the count hardcoded to one
- **Refills when the round turns over**, not on the combatant's own turn —
  unlike `Reaction`. A Legendary Action budget is meant to be spent across
  every other combatant's turn in the round, so tying its refill to its
  owner's own turn (the way `Reaction` works) would refill it before it's
  had the chance to be spent
- Lives in its own "Actions" card with Reaction and Concentration — a
  2-column grid above Effects, not a chip under it, since a DM checks these
  every single turn regardless of what conditions are active
- Created via a compact modal (name + a count stepper); the cog on an
  existing one reopens the same modal to rename it, change the count, or
  remove it

### Changed — combatant screen: two-column grids, one Recharge, smaller title fields

- **Effect chips are laid out as a fixed two-column grid**, not a wrapping row
  of variable-width chips — every chip gets the same, bigger tap target
  regardless of label length, and the grid reads top-to-bottom instead of
  like a paragraph
- **The three named "Recharge 5–6/6/4–6" cooldowns collapsed into one plain
  "Recharge"** — the DC was always the DM's own number in their head; the app
  only needed to remember that a roll was owed, and three near-identical
  picks for that was clutter the app itself was creating
- **The combatant detail screen's title is the combatant's name**, not the
  word "Combatant" — and the editable Name field moved to the bottom of the
  identity card, since the title now covers the common case of just reading it
- Dropped the "the app never rolls, it just remembers you owe one" caption
  from the effect and round-effect editors — said once in this changelog and
  in SPEC is enough; repeating it on every single effect was exactly the kind
  of thing that stops reading as information

### Changed — minimal-taps pass: renamed, no confirm on rolls, compact prompt

- **App renamed to "Combat Companion"** on the home screen (`CFBundleDisplayName`
  only — bundle id, module name and the Xcode project stay `initiative`, so this
  doesn't touch code signing or require reinstalling)
- **Answering a roll prompt (Success/Failure, Held it/Lost it, death saves) no
  longer needs a Continue button.** Tapping the answer resolves it immediately;
  the sheet dismisses itself the instant every prompt has one. This is the
  middle of combat — a mis-tap is rare and cheap to fix by hand, and paying for
  that on every single roll with an extra confirmation tap was the wrong trade
- **`TurnPromptView` is a compact modal, not a full screen** — it measures its
  own content height and feeds that back into `.presentationDetents` instead of
  claiming a fixed fraction of the display, so a one-line prompt gets a
  one-line sheet
- **Reaction and concentration are just effects among the others now** — folded
  into the same tap-to-apply grid as the standard conditions (first two chips,
  since they're checked every turn) instead of each getting its own card
- Effect chips are bigger (larger tap target, bigger icon) — pressed mid-combat,
  where a bigger target beats a denser grid
- Name/initiative/AC/HP boxes on the combatant detail screen are a bit smaller,
  freeing up room for the bigger effect chips below

### Changed — effects screen folded into the combatant detail view

- **Removed the "Manage" button and its separate `EffectsView` screen.** The
  tap-to-apply grid of conditions now lives directly on the combatant detail
  screen, so applying "Stunned" is one tap from opening the combatant instead
  of two, and there's no longer a distinct "Active" list next to the grid —
  an active condition is just the chip, colorful with a checkmark
- **A gear icon appears on an active chip** as a second, independent tap
  target, for the minority of cases that need a different duration than the
  default. `EffectEditorView` is down to two questions: which edge of the turn
  it keys off, and a "Requires a save" toggle (on by default) that reveals a
  turns stepper when switched off — "until removed" isn't an option there
  anymore, since those conditions clear the same way they're applied, by
  tapping the chip off again
- **Concentration is now a plain toggle on the combatant**, not a named
  `Effect` — nothing to configure, so nothing to clutter. Taking damage while
  it's on still raises the same turn-prompt mechanism, inverted the same way
  as before

### Added — round-anchored effects

- **Effects can belong to the fight rather than to a creature** — a collapsing
  bridge, an environmental hazard. `DurationType.forRounds(remaining:)` counts
  down when the round turns over, not on anyone's turn
- They live on the session, which is the point: pinned to whichever combatant was
  handy, an effect vanishes when that combatant dies and fires on their turn
  instead of at the top of the round. Both have tests
- Rolls owed by one come due when the round wraps. `TurnPrompt.combatantID` is
  now optional — the round belongs to no one — and the prompt reads "The round"
- A pinned strip above the roster shows what's in play; managing them is its own
  screen, since almost nothing carries over from the per-combatant one (a bridge
  isn't Frightened)
- Part of the undo history and of `SessionRecord`, so Previous restores a
  countdown and older saves load empty

That closes the effects work. Ongoing damage, limited uses and linked
concentration were dropped rather than deferred — see SPEC → Declined.

### Fixed

- **Player view was hiding the party's numbers too.** The combatant tag existed
  but player view never consulted it — it's for turning the screen around, and
  the party already know their own hit points; it's the monsters' numbers that
  need hiding

### Added — concentration and temporary HP

- **Concentration** is a third `EffectKind` — not something wrong with you, not
  something you can't do yet, but something you're *holding*. Taking damage
  raises a check: **the one prompt in the app not tied to a turn boundary**,
  because damage isn't either
- Its resolution is **inverted from every other prompt** — failing is what
  removes it, since the roll is to keep the thing rather than shake it off. The
  labels say so: **Held it** / **Lost it**
- The prompt reports the **damage taken, not a DC**. The threshold is a rule and
  rules are the DM's; what the app knows is how hard they were hit. Being dropped
  to 0 ends it outright without asking
- **Temporary hit points**, granted from the Health card and shown in the combat
  row as `26/30 +8`. Absorbed before real HP, not refilled by healing, and gone
  rather than zero once spent
- Granting replaces rather than stacks — two sources don't add, and replace is
  what a DM can predict without the app holding a rule about which is larger
- The buffer participates in the log, which is the HP undo mechanism: deleting a
  damage entry would otherwise recompute HP without the buffer that absorbed it.
  The live and replay paths share one `absorb` function so they agree by
  construction

### Added — tap-to-apply effects screen

- **`EffectsView` replaces the Add Effect form.** All sixteen conditions are
  visible at once as chips; **one tap applies one** with the duration that
  condition usually wants. Tapping an already-applied one opens it for
  configuring — by then you've said which condition you mean, and the only
  question left is the duration. "This creature is stunned" went from four
  decisions to one
- Active effects are listed above the grid with their durations spelled out, and
  swipe to remove. A chip can show *that* something is on but not for how much
  longer, and the duration is what you actually check mid-combat
- Cooldown quick-picks and a Custom effect entry live on the same screen, so
  everything affecting one combatant is in one place
- `EffectEditorView` is what's left of the old form: naming a custom effect, and
  fixing a duration the default guessed wrong. Both are the uncommon path now
- Adding, removing and updating effects moved onto `CombatSession` so they're
  testable and so every path logs identically — an effect appearing or going is
  as much a part of what happened as a hit point change, and now shows up in the
  log

### Fixed

- **Every Form in the app was rendering system-grey rows in all nine themes.**
  `listRowBackground` was attached to the `Form` rather than to its rows, where
  it's silently ignored — the accent tint propagated, which is why it looked
  half-right. Now attached per `Section`
- The Health card's **Amount fields were 66pt against Current/Max at 74pt**. They
  sit in two stacked rows and read as a grid, so the columns visibly failed to
  line up. All four share one width now
- **Removing a combatant no longer asks for confirmation.** Swipe-to-reveal plus
  a tap on Delete is already two deliberate actions, and it's the pattern every
  other list in the app uses
- `StandardCooldown`'s "Once per encounter" was faking "until removed" with a
  99-turn countdown, which would eventually have surfaced as "98 turns left"

### Added

- **`DurationType.untilRemoved`** — for conditions countered by doing something
  about them rather than by a clock. Research into how conditions actually end
  found the governing rule is that a condition lasts *until it is countered, or
  for a duration the source specified*: duration belongs to the source, not the
  condition. Three shapes follow, and **six of the sixteen** standard conditions
  want this one — Prone (stand up), Grappled (escape, and *when you choose to
  act*, so a turn-boundary prompt would nag about a roll you may not be
  attempting), Unconscious, Burning, Exhausted, Invisible
- **Each condition now carries the duration it usually wants**, so picking Prone
  prefills "until removed" and picking Frightened prefills a save. Tendencies,
  always overridable — but picking used to prefill a countdown every time, which
  was wrong for more than half of them

### Added — recharges, save-ends conditions, and death saves

- **Effects can now wait on a roll instead of a countdown.**
  `DurationType.untilRollSucceeds(at:hint:)` never ages out — it sits there until
  the DM says the roll succeeded. A dragon's recharging breath weapon and a
  save-ends condition are the same rule from two sides; only the verb differs,
  which the new `EffectKind` (`.condition` / `.cooldown`) supplies. That
  collapse is a direct consequence of the app not rolling
- **The turn prompt**: rolls owed at a turn boundary are asked once, together,
  and **must be answered** — the turn doesn't advance until they are. End-of-turn
  rolls for the combatant finishing and start-of-turn rolls for the one starting
  appear in the same sheet, since it's one interruption at the boundary rather
  than two either side of it
- Answers ride inside the same undo step as the advance, so **Previous rewinds
  the save you just recorded** along with the turn it belonged to
- **Death saves.** A player at 0 HP starts rolling; one tap per turn for Success
  or Failure, three of either resolving it. Healing above 0 ends it, and so does
  deleting the log entry for the blow that caused it. Stabilised is a real third
  state — 0 HP, not rolling, explicitly not dead — and the row shows dying,
  stabilised and dead differently
- **A player/NPC tag** on creatures and combatants. Built-ins are NPCs, hand-made
  creatures default to player, and the toggle is visible in the Add Combatant
  sheet at the moment of creation. An NPC at 0 HP still simply dies, which is the
  whole reason the tag exists — otherwise every killed goblin would acquire a
  three-turn clock
- Cooldown quick-picks (`StandardCooldown`: Recharge 5–6, 6, 4–6, Once per
  encounter) so the common cases are one tap, and cooldown chips take the quiet
  treatment the reaction chip already uses
- **The app still never rolls.** Its job is remembering that a roll is owed

### Added — searching and sectioning the libraries

- **Search on both Creatures and Encounters**, pinned at the bottom of the
  screen rather than under the navigation title: it's where the thumb is on a
  phone held one-handed, and the combat screen already puts its controls in a
  bottom bar. One `SearchBar` component, applied identically to both
- Terms are ANDed but may match different fields — "giant spider" doesn't return
  every Giant, and "troll boar" finds the Bridge Troll encounter, whose *name*
  contains neither word. Matching is case- and diacritic-insensitive
- **Both lists split into "Yours" above "Included"**, so the few things you made
  aren't buried in seventy built-ins. Origin is decided by name, so renaming a
  default makes it yours while editing its stats doesn't — no change to the
  on-disk format, and nothing to fall out of step with the roster
- Creature rows lay their stats out across rather than stacked, halving row
  height. Stacked, three stats made every row three lines tall, which at 70-odd
  creatures cost more scrolling than the aligned columns were worth

### Changed — built-in content is read-only

- **Built-in creatures and encounters can no longer be deleted, renamed, or
  edited.** They're a fixture, not a starting point to whittle down. Rows offer
  **Duplicate** where the user's own offer Delete, and tapping one opens the
  familiar sheet with every field disabled and Duplicate where Save would be
- Copies are named "Goblin Copy", then "Goblin Copy 2"… and land in **Yours**,
  fully editable
- **`upsert` no longer modifies a built-in.** Adding a combatant called "Goblin"
  with 12 HP was quietly rewriting the built-in Goblin's stats — an edit to
  read-only content through the back door, from a screen that isn't even the
  Creatures list
- **The install ledger is gone**, and with it `DefaultInstallLedger`. Its only
  job was telling "new in this version" apart from "deleted on purpose", and
  deleting a built-in is no longer possible — so `installDefaults()` is now a
  plain what's-missing check. A built-in that goes missing (an older version, or
  renamed away) comes back on the next launch

### Changed — combat screen controls

- **"+" moved to the top right**, where it is on every other screen, and the
  session options menu (player view, log) took its place at the bottom centre.
  The one action that's the same everywhere is now in the same corner
  everywhere, and the two controls that exist only during combat sit together
  with the turn controls

### Removed

- **Restore Defaults, on both screens.** Superseded: with built-ins undeletable
  there is nothing to restore. `restoreMissingDefaults()` went from both stores
  rather than being left as an API with no caller

### Added — starter content

- **The default creature roster grew from 11 to 71** — beasts, people, warbands,
  the restless dead and monsters, with HP/AC/initiative bonus across the whole
  range from a 7 HP minion to a 178 HP session-ender. Names stay generic folklore
  and the numbers are plausible rather than copied
- **Ten ready-made encounters** (`Goblin Ambush`, `Toll Bridge`, `The Crypt
  Stirs`, `The Wyrm's Approach`, …), ordered easiest first. Each is a *shape* — a
  swarm of weak things, a leader with escorts, one large threat — so it's usable
  as-is or as a starting point to edit
- Both live in one `DefaultContent` table. Encounters name their creatures rather
  than restating stats, with `DefaultContentTests` pinning that every line
  resolves — a typo would otherwise install an encounter whose combatants have no
  HP or AC, and nothing at runtime would notice

### Fixed — defaults are additive, not all-or-nothing

- **Default content added in a later version now actually reaches you.** Seeding
  ran only when the store was completely empty, so anyone who had already used
  the app would never have received the 60 new creatures or any of the
  encounters. A `DefaultInstallLedger` records what has ever been *offered*, so
  something new gets installed, something deleted on purpose stays deleted, and a
  preset you've edited is never overwritten by its default
- Related: a single custom creature created before the first launch used to cost
  you the entire starter roster permanently
- **List rows shrink-wrapped instead of filling the row** unless their content
  happened to contain a `Spacer` — visible as a ragged right edge down the whole
  Encounters list. `cardRowStyle` now claims the width itself

### Added — selectable themes

- **Four themes, picked from Main Menu → Appearance** (`AppearanceView`), each
  option drawn in its own colors since a palette is the one setting whose label
  can't describe the choice:
  - **Tavern Candlelight** (default, unchanged) — warm near-black, candle gold
  - **Ink & Cinnabar** — cool blue-black ground, warm off-white text, one
    cinnabar accent. The cool-ground/warm-ink pairing is a printed-page
    relationship rather than a screen one, which carries the serif without
    reading as generic fantasy
  - **Slate & Brass** — blue-grey stone, muted brass. The quiet one
  - **Verdigris** — damp stone and oxidised copper
  - **Abyssal** — deep water; the one palette whose accent is colder than its
    ground
  - **Nightshade** — violet-black with a luminous green complement
  - **High Contrast** — pure black/white and saturated status colors; a
    legibility setting rather than a mood, and the one palette that deliberately
    breaks the muted-colors house rule
  - **Parchment** — light: warm paper, near-black serif, oxblood accent
  - **Vellum** — light and cool: grey paper, deep teal ink
- The picker splits dark from light, since that's the first decision a person is
  actually making
- **`ThemePalette` / `ThemeIdentifier` / `ThemeController`**: colors moved out of
  `Theme` into a value type, with `Theme`'s accessors forwarding to the selected
  palette. No view was edited to support this — because `ThemeController` is
  `@Observable` and SwiftUI's observation tracking follows reads through static
  accessors, `Theme.surface` re-renders on change on its own. Selection persists
  in `UserDefaults`; an unrecognised stored value falls back to the default
- A palette declares its own `colorScheme`, forced app-wide, so system-drawn
  chrome follows a light theme too. `Theme.applyNavigationBarAppearance()` now
  also updates live nav bars, since `UINavigationBar.appearance()` alone only
  affects bars created afterwards
- `Theme.accentForeground`, for content sitting on an accent fill. Previously
  `Theme.background` was reused for this, which only works while the accent is
  guaranteed lighter than the page — untrue in Parchment
- **`ThemePaletteTests`**: the design rules asserted against every palette rather
  than whichever is selected — monotonic and perceptible elevation ladder, WCAG
  contrast per text level per surface, accent legibility, declared-vs-actual
  color scheme, and nothing within 0.3 RGB of the accent. Plus
  `ThemeControllerTests` for the persistence edges (fresh install, relaunch,
  unrecognised stored value)

### Fixed

- **`statusWarn` was 0.09 RGB from the accent in Tavern Candlelight** — an amber
  "Wounded" band in a row beside the current-turn numeral read as a second
  current-turn marker, exactly the collision the accent rule exists to prevent.
  Now orange. Found by the new per-palette test, not by eye
- Condition category colors were hardcoded in `ConditionCategory` and now come
  from the palette, so switching themes actually recolors the chips

### Changed — design system overhaul

- **`Theme` is now a full token set, not just colors**: `Theme.Spacing` (4pt
  scale), `Theme.Radius`, and `Theme.Typography` join the palette. Views no
  longer carry literal padding numbers, corner radii or `.font(.headline)`
  calls — the ad-hoc 6/8/12/14/16/26/32 spacing scattered across screens is
  gone
- **Real elevation ladder** replaces the single flat brown: `background`
  (near-black warm ink) → `surface` (cards/rows) → `surfaceRaised`
  (inputs/chips/current turn), plus a low-contrast warm `backgroundGradient`.
  Deepening the base is what lets the candle-gold accent read as *light*;
  previously the background sat close enough to the accent that gold never
  glowed
- **Borders are hairline** (`Theme.hairline`, 0.75pt at reduced opacity)
  instead of full-weight 1pt strokes on everything, which is what made the UI
  read as boxes drawn around things rather than as surfaces
- **Accent is now spent on one thing per screen.** In the combatant list only
  the *current* combatant's initiative numeral is gold; the rest are
  `textSecondary`. The current-turn row is marked by a surface lift + accent
  outline + a 3pt accent bar down its leading edge (the bar is what makes it
  findable while scanning the initiative column) rather than by a tinted wash
- **Typographic voice**: serif (`Typography.rowTitle`/`.title`/`.display`, and
  the nav bar title) for anything that names something — screen titles,
  combatant/creature/encounter names, card headings. Rounded *monospaced
  digits* for initiative/HP/AC so the stat columns stop jittering between
  one- and two-digit values. Tracked uppercase captions for field labels
- **Condition colors are now semantic.** `StandardCondition` carries a
  `ConditionCategory` (`sensory`/`mental`/`restraint`/`disabling`/`ongoing`)
  and takes its color from that, replacing 10 raw SwiftUI system hues
  (`.pink`, `.purple`, `.cyan`, `.indigo`, `.yellow`, …) that clashed with the
  warm palette and told the DM nothing the label didn't. Chip color now says
  *which kind* of trouble a combatant is in. The old "Stunned" yellow in
  particular sat close enough to candle gold to compete with the current-turn
  marker; a test now enforces that no category drifts back toward the accent
- **Navigation bar is themed** via `Theme.applyNavigationBarAppearance()` from
  `RootView.init` — `.preferredColorScheme(.dark)` alone left it on UIKit's
  neutral system gray, which read as a foreign slab against the warm palette
  (there is no SwiftUI-level way to set a nav bar background color)
- **Main menu** leads with exactly one filled accent button — Resume when
  there's something to resume, otherwise New Session — with the rest as quiet
  surface rows. Decorative `.circle.fill` icon variants dropped throughout
- **Combatant detail** groups into cards with proper heading hierarchy
  (`Text.cardHeading()` for card titles vs `Text.sectionLabel()` for field
  labels); Initiative and Armor Class now sit side by side instead of each
  taking a full-width row; damage/heal/max buttons are matched tinted discs
- **"Restore Default Creatures"** moved from a bare bar button beside Back —
  where a mistimed tap on the way out silently repopulated the list — into the
  Creatures screen's top-right options menu
- Amount fields on the detail screen show `–` rather than `0` as placeholder,
  which read as a real value

### Added

- `View.themedScreen()`, `cardRowLayout()`, `sectionCard()`,
  `fieldStyle(width:)`, `Text.sectionLabel()` and `Text.cardHeading()` in
  `ViewExtensions.swift` — the row/card/field/label chrome that had been
  copy-pasted per screen (the detail screen alone repeated the same bordered
  `TextField` treatment eight times) now has one definition each
- `Theme.surface` / `.surfaceRaised` / `.backgroundLift` / `.backgroundGradient`
  / `.ember` / `.accentSoft` / `.border` / `.hairline`
- `UIFont.serif`, so `SelectAllTextField` (a UIKit bridge, and therefore
  outside SwiftUI's font handling) can match the app's serif voice
- **32 new tests** (113 → 145), covering three previously untested areas:
  - `CodableCompatibilityTests` — saved sessions are a durable on-disk format
    (see CLAUDE.md, "Session persistence compatibility") and had no tests at
    all. Decodes *literal legacy JSON* rather than round-tripping through the
    current encoder, so it still fails if a future change breaks yesterday's
    files: retired `untilStartOfTargetTurn`/`untilEndOfTargetTurn` duration
    kinds collapsing into owner-turn equivalents, missing `remainingTurns`
    defaulting to 1, absent `isReactionMarker`/`roundNumber`/`log`/HP/AC
    fields, and a full legacy `SessionRecord` loading end to end
  - `StatusBandTests` — the player-facing health/armor bands, including the
    strict `>50%` / `>25%` boundaries and the negative/zero-max edge cases
  - `ConditionsTests` — case-insensitive lookup, unique names and symbols, and
    the design constraint that no category color approaches `Theme.accent`
- `NewSessionView` shows a per-encounter creature/combatant count, and reads
  the encounter list once per appearance rather than hitting disk inside `body`

### Fixed

- `StatusBand.health` guards against a non-positive `max`, which would
  otherwise produce a meaningless fraction (NaN at exactly zero, where every
  comparison is false) instead of a sensible band

### Added
- **New Session picker screen** (`NewSessionView`) replaces the earlier
  `confirmationDialog` action sheet for choosing Fresh Session vs. a saved
  encounter — a proper list screen styled like the rest of the app instead
  of the one native-chrome sheet left in an otherwise fully custom-themed app
- `Theme.placeholderText` — a lighter warm tan for `TextField` placeholders.
  Plain `TextField("placeholder", text:)` always renders its placeholder in
  a fixed system gray regardless of app theme; every placeholder-bearing
  field across the app switched to the `TextField(text:label:)` closure
  form so the placeholder can actually be recolored
- `View.cardRowStyle(isHighlighted:)` (`ViewExtensions.swift`) — the
  bordered-card look from the combat screen's combatant rows (border always,
  accent-tinted fill + thicker border when highlighted), now shared by every
  list in the app (Creatures, Encounters, Load Session, New Session) instead
  of being unique to the combat screen
- **Restore Defaults** button (top-left of Main Menu → Creatures,
  `arrow.counterclockwise`) — `PresetStore.restoreMissingDefaults()` adds
  back any default creature whose name isn't currently present, without
  touching existing presets. Fixes defaults silently never appearing: the
  first-launch seed only fires once on a truly empty store, so adding or
  editing even one preset before that (or deleting a default later) lost
  the rest permanently with no way back until now

### Changed
- Bigger Add Combatant "+" icon in the combat screen's bottom bar (18pt
  semibold -> 26pt bold)
- Health section split into two rows — Current HP with its own Amount
  field + Damage/Heal buttons, Max HP below with its own Amount field +
  a blue heart-plus Increase-Max-HP button — instead of one shared Amount
  field feeding all three actions, which put Increase Max HP oddly far
  from the Max HP box it actually affects
- Damage/Heal/Increase-Max-HP button colors desaturated: new
  `Theme.statusInfo` (muted blue) added alongside reusing `Theme.statusBad`/
  `.statusGood` (muted red/green), replacing raw SwiftUI `.red`/`.green`/
  `.blue` which read as too saturated against the rest of the palette

### Fixed
- FlowLayout status chips could still clip with enough statuses to wrap
  multiple lines — the previous fix (measuring width via a `GeometryReader`
  background + `@State`) updated a frame too late: `List` self-sizes a row
  once on first appearance and doesn't re-measure afterward, so the row's
  committed height stayed based on the pre-measurement (unwrapped) guess.
  Now computed synchronously from screen width up front, no async
  measurement involved, so the first layout pass already has the right value

### Changed
- Main menu drops the "Combat Tracker" subtitle — just "Initiative" now
- Combat screen toolbar: the trailing Add button is now a hamburger menu
  (`line.3.horizontal`) containing the DM/player-view toggle and "Log" —
  frees the bottom bar's middle slot
- Bottom bar: Add Combatant moved to the middle slot (`+` icon) where
  Log/eye used to be; Previous/Next unchanged
- Combatant list row: removed the arrow icon on the current-turn row — the
  row's background fill + border now solely indicate whose turn it is
- Combatant rows now have a visible border always, and a stronger
  accent-tinted fill + thicker border when it's the current turn (previously
  just a faint background tint, no border at all otherwise)
- HP/AC on the combatant list switched from text labels ("14/20 HP", "AC 15")
  to a heart icon (HP) + shield icon (AC), left-aligned in their own column
  so the icons line up regardless of digit count
- Reaction icon changed again, from `arrow.triangle.2.circlepath` to
  `arrow.uturn.left` — closer to the "half-circle back-and-forth arrow" the
  user described, still distinct from every `ConditionLibrary` icon
- Damage/Heal amount field shrunk to fit its content (a short number, ~60pt)
  instead of stretching to fill the row
- Added `Theme.inputBackground` — lighter than `Theme.background` — and
  applied it to every text input across the app (CombatantDetailView's
  custom bordered fields, and Form-based `Section`s in every Add/Edit sheet)
  so inputs read as distinct fields instead of matching the page behind them
  or falling back to a system dark-gray Form row background
- Every screen now uses `Theme` colors — Encounters, Creatures, Load
  Session, Log, and every Add/Edit sheet were still using system-default
  white `Form`/`List` backgrounds and `.secondary` text, unthemed. Added
  `Theme.background` + `.scrollContentBackground(.hidden)` to each, and
  swapped `.secondary`/system-default text colors for `Theme.textPrimary`/
  `.textTertiary`. Also added `.preferredColorScheme(.dark)` + `.tint(Theme.accent)`
  at the app root (`RootView.swift`) — Tavern Candlelight is a dark palette,
  so this makes every remaining system-provided color (native toolbar chrome,
  placeholder text, etc.) follow dark-mode automatically instead of
  potentially clashing when the device itself is in light mode
- **Theme finalized: Tavern Candlelight** — dark warm brown background, amber
  accent, cream text, replacing the earlier "old paper" rust-red-on-white
  look. `Theme.swift` is back to plain `static let` constants (the temporary
  `ThemeManager`/`ThemePicker`/`ThemePalette` comparison tooling removed);
  `CLAUDE.md` and `SPEC.md` updated to say theme applies app-wide now, not
  selectively
- Health/armor status bands recolored to warm-toned semantic colors
  (`Theme.statusGood`/`.statusWarn`/`.statusBad`/`.statusNeutral`) instead of
  raw `.green`/`.orange`/`.red`/`.blue`, so they don't clash with the warm
  background. AC band labels changed from "Low/Average/High AC" to
  "Unarmored"/"Lightly Armored"/"Heavily Armored"
- Combatant list row layout reworked to use its full width: HP/AC moved from
  a cramped caption line under the name to a right-aligned column near the
  current-turn arrow, putting the row's previously-empty middle space to use
- Session name/placeholder text in `SelectAllTextField` (the UIKit bridge
  behind the session-name field) now follows the theme — it was silently
  defaulting to UIKit's black text/gray placeholder regardless of palette
- Reaction icon changed again, from `hand.tap`/`hand.tap.fill` to
  `arrow.triangle.2.circlepath` (a curved back-and-forth arrow — same glyph
  for both states, just recolored between accent/tertiary). List chip label
  changed from "Used" to "Reaction"

### Added
- **Temporary theme picker** (paint palette icon, top-right of the main menu)
  for comparing 5 color palettes live: the original Rust & Paper, plus Ink &
  Parchment, Dungeon Stone, Tavern Candlelight, and Old Map. `Theme.swift`
  now sources its colors from a switchable `ThemeManager.shared.palette`
  instead of hardcoded constants. Marked TEMPORARY in code comments — once a
  palette is chosen, hardcode it back into `Theme` and delete `ThemeManager`/
  `ThemePicker`/`ThemePalette.allCases` and the menu button

### Changed
- Damage/Heal/Increase-Max-HP controls consolidated into one row: the amount
  field plus three equal icon-only buttons (minus/plus/up-heart) next to it,
  replacing the old layout (amount field, then a two-button Damage/Heal row,
  then a separate full-width "Increase Max HP" row below) that felt like the
  actions were "placed a bit everywhere" per feedback
- Combatant list's status row reworked into wrapping chips: each active
  status (reaction used, each effect) now gets its own small darker rounded
  box with an icon + short label (e.g. "Stunned", "Used"), laid out via a
  new `FlowLayout` (`Theme.swift`) that wraps to the next line on overflow
  instead of clipping. Replaces the earlier bare-icons-in-a-row version and
  the `LetterBadge` component (removed, now unused)
- Reaction's icon changed from the custom "R" `LetterBadge` to SF Symbols
  `hand.tap.fill`/`hand.tap` — deliberately not `bolt.fill`/`bolt.slash.fill`,
  which are already used by the Paralyzed/Incapacitated standard conditions
- Combat Log now reads chronologically (oldest round/entry first, like a
  chat log) instead of newest-first, and opens scrolled to the bottom
  (most recent entry) via `ScrollViewReader` — that's almost always what
  you want to see first anyway
- Reaction-used is no longer specially called out with its own text row on
  the main combatant list — it's just another symbol (the red "R"
  `LetterBadge`) alongside the effect condition icons. And that whole status
  row now shows symbols only, no text names — full names/durations are
  reserved for the combatant detail screen
- Combatant detail screen no longer hides exact HP/AC in player view — it
  always shows editable exact numbers now, regardless of the toggle.
  Tapping into a creature is a deliberate DM action, not something a player
  glances at over their shoulder the way the main list might be, so an
  approximate mode there added friction without protecting anything. The
  player-view toggle now only affects the main combatant list

### Fixed
- Session name still wasn't centered to the true phone-screen center after
  the eye-icon toolbar fix — `.principal` centers relative to leading/
  trailing button widths, not the true center, and "Menu" (icon+text) vs
  "Add" (icon-only) are unequal widths. Moved the name back into the body
  as its own centered row (same fix already used for the bottom bar's Log
  button) instead of the toolbar

### Changed
- Main combatant list now shows HP/AC again (when set) — exact numbers in DM
  view, the same approximate bands as the detail screen in player view.
  Reverses the earlier "spoiler-free list" decision on direct instruction.
  `healthBand`/`armorClassBand` extracted to a shared `StatusBand` enum
  (`Theme.swift`) so the list and detail screen read identical bands instead
  of two copies that could drift

### Fixed
- Armor Class was hidden entirely (not shown as an approximate, just gone) in
  the combatant detail screen when player view was on — now shows a Low/
  Average/High AC band, mirroring the existing HP health band, instead of
  disappearing
- Session name field wasn't actually centered once the DM/player-view eye
  icon was added as a second trailing toolbar button — root cause was nav bar
  `.principal` centering relative to leading/trailing button widths, not the
  true screen center. Fixed by removing the eye icon from the toolbar
  entirely (see Changed below) rather than moving the name out — with only
  "Menu" and "Add" left flanking it, `.principal` centers correctly again

### Changed
- The DM/player-view eye toggle moved out of the toolbar (where it was a
  second trailing icon competing with "Add" and skewing the session-name
  centering) into a small icon in the bottom bar next to Log. There is now
  exactly one control for it, not a duplicate copy on the combatant detail
  screen's Health header — removed that one too
- Effect durations simplified: dropped "until start/end of **target's**
  next turn" entirely (effects are always self-applied to the combatant
  they're on, so a "target" concept never made sense) and added an optional
  turn count instead — durations are now "until start/end of their turn",
  repeatable across N turns via a stepper (default 1) rather than a
  one-off single-turn expiry only
- Combatant list row no longer shows "Reaction available" — only "Reaction
  used" appears, and only when true. Available is now the implied default
  (absence of the badge), matching how the effects list already only shows
  active effects rather than a placeholder for every possible one. The
  detail screen's reaction toggle is unchanged (it needs to show both states,
  since that's the actual control)

### Added
- **Armor Class**: opt-in per combatant (`Combatant.armorClass`,
  `CreaturePreset.armorClass`), editable everywhere HP already was. Confirmed
  "AC"/"Armor Class" is a generic tabletop term, not trademarked, before adding
- **Standard status conditions** (`Conditions.swift`): Blinded, Charmed,
  Deafened, Frightened, Grappled, Incapacitated, Invisible, Paralyzed,
  Poisoned, Prone, Restrained, Stunned, Unconscious, Exhausted, Burning,
  Bleeding — each with an SF Symbol icon + color, quick-picked from a new
  "Choose Condition" menu in Add Effect. Effect badges (list row + detail
  screen) now show the matched icon/color instead of a generic sparkle.
  Confirmed condition names aren't trademarked/copyrighted (single descriptive
  words like "stunned" aren't ownable) and SF Symbols are licensed for in-app
  UI use before building this
- **DM/Player view toggle**: HP is no longer shown on the main combatant list
  at all (regardless of the toggle) — just name/initiative/reaction/effects.
  The detail screen's eye icon (also mirrored in the toolbar) switches between
  exact DM view (editable HP/AC, damage/heal controls) and player view (a
  single approximate health band — Healthy/Wounded/Critical/Dead, deliberately
  generic wording — with AC hidden entirely). `CombatSession.playerViewEnabled`
  is a live UI mode, not persisted
- **Encounters**: prepare a named creature list ahead of time (Main Menu →
  Encounters), then start a session already populated with it via a new
  "Fresh Session" vs. saved-encounter chooser on "New Session". Entries are
  stat snapshots, not live preset references, so editing/deleting a preset
  later doesn't retroactively change an existing encounter. Initiative is
  always rolled fresh per combatant at session start, never stored in the
  encounter
- Creatures screen: can now create a new preset directly (top-right "+"), not
  just edit ones that originated from adding a combatant in a session
- Session title field now selects all its text on focus (`SelectAllTextField`,
  a small `UITextField` bridge — plain SwiftUI `TextField` has no pre-iOS-18
  way to do this) so renaming doesn't require manually clearing the old value
- Explicitly excluded per direct instruction: legendary/lair actions, held/
  delayed turns, private per-combatant notes

### Fixed
- Main menu button icons had different intrinsic widths (play vs. pawprint vs.
  shield glyphs), so button text started at a different x-offset per button —
  fixed with a fixed-width icon frame so all button labels align
- Previous/Next Turn buttons shortened to "Previous"/"Next" (dropped the
  redundant "Turn" — implied by context) and toolbar "Add" became a plus icon,
  matching standard iOS conventions

### Changed
- **Reaction tracking reimplemented internally as a regular effect.** Using a
  reaction now appends an `Effect(.untilStartOfTheirTurn, isReactionMarker: true)`
  to the combatant instead of setting a separately-stored bool — it expires
  through the same `removeExpiredEffects` pass every other effect already uses,
  so `nextTurn()` no longer needs its own bespoke reaction-reset line.
  `Combatant.reactionUsed` is now computed (`effects.contains { isReactionMarker
  == true }`); `useReaction`/`resetReaction`/`toggleReaction` on `CombatSession`
  replace direct bool mutation. New `Combatant.visibleEffects` filters the
  marker out of the user-facing effects list (it has its own dedicated Reaction
  UI). No user-visible behavior change — purely an internal simplification
- Reaction indicator replaced the SF Symbol checkmark/xmark with a custom red
  "R" badge (`Theme.LetterBadge` — a `Circle` + `Text`, no image asset
  needed): filled red when available, outlined/muted when used. Used both on
  the combatant list row and the detail screen's reaction toggle for
  consistency

### Fixed
- Reaction status ("Reaction available"/"Reaction used") on combatant list
  rows wasn't horizontally aligned between combatants — it was appended after
  Init/HP on the same line, so its position shifted depending on whether a
  given combatant had HP tracked. Moved to its own row, always leading-aligned

### Added
- **Log entries are now editable, scoped to HP.** Damage/healing/max-HP-increase/
  HP-tracking-started entries carry structured data (`HPOperation` enum + target
  combatant id) behind the display text; swiping one away recomputes that
  combatant's current/max HP from the remaining entries via
  `CombatSession.deleteLogEntry`/`recomputeHP`. Turn changes, add/remove, and
  deaths stay non-deletable for now — undoing those safely means touching
  derived turn order, which is a bigger, riskier change than fixing an HP
  typo; discussed the scope with the user before building rather than
  guessing at it
- Log view now groups entries into sections by round number, newest round first
- Add-combatant modal: "Choose Creature" menu listing saved presets by name
- Removed the extra delete-confirmation dialog for creature presets — swipe +
  tap Delete is already two deliberate actions, matching sessions/combatants

### Changed
- Add-combatant modal field order: Name, Max HP, Count, Initiative (Initiative
  moved last since it's the field most often left blank)
- `addCombatants` no longer forces independent random rolls when count > 1 and
  an explicit initiative is given — every spawned copy now gets that same
  value, matching what you'd expect from typing a number. Still rolls
  independently per copy when initiative is left blank

### Fixed
- Real bug found while building the above: combatants created with Max HP set
  *at add time* (vs. later via "Track HP") had no `.enableTracking` log entry,
  so deleting an unrelated HP entry for them would recompute to nil HP,
  wiping them. Both `addCombatant` and `addCombatants` now log that baseline
  entry whenever `maxHP` is provided at creation
- Bottom bar's Log button wasn't actually centered — the two-`Spacer()` layout
  only balances the gaps around it, not the true bar center, when the side
  buttons ("Previous Turn" vs "Next Turn") have unequal widths. Fixed with
  three equal-width flexible columns instead

### Added
- Add-combatant modal now has a "Choose Creature" menu listing saved presets
  by name — picking one fills Name + Max HP directly (an explicit full
  overwrite, unlike the passive typing-based auto-fill which only fills HP if
  still empty)
- **Combat log**: `CombatSession.log` ([LogEntry]), appended on turn changes,
  damage/heal/max-HP-increase, deaths, and combatant add/remove. New "Log"
  button in the bottom bar (center, between Previous/Next Turn) opens a
  read-only `LogView`. `Previous Turn` now truncates the log back to its
  state before the turn being undone — the existing turn-revert history
  snapshot also stores the log length at that point. Persisted with the
  session (`SessionRecord.log`, optional for old-save compatibility)

### Changed
- **Add Combatant moved to a top-right toolbar button**; the bottom-of-list
  placeholder row is gone. Discussed placement/log design with the user before
  building rather than guessing
- Round counter removed from the toolbar (was squeezed out by the Add button
  anyway) — the centered plain-text display above the list remains the only
  round indicator
- Confirmed Previous/Next Turn's Liquid Glass qualifies per Apple's own
  examples (media transport controls, which don't navigate either, are
  explicitly called out as appropriate) — bar now also carries the Log button
  with the same glass treatment (`.glass`, non-prominent)

### Added
- **Increase Max HP**: `CombatSession.increaseMaxHP(for:amount:)` raises both
  max and current HP together (a buff/level-up, not just a higher ceiling) —
  new third button on the combatant detail screen reusing the existing amount
  field alongside Damage/Heal
- Four more starter creatures: Ogre, Giant Spider, Giant Rat, Cultist —
  fills out brute/ambusher/swarm-filler/caster roles the existing seven didn't
  cover, HP + initiative bonus researched for realism

### Fixed
- **Main menu "Resume" could show stale, wrong state** (e.g. still red/enabled
  right after deleting the session it pointed at). Root cause: `canResume` was
  a computed property calling `SessionStore.resumableSession()`, which reads
  UserDefaults/disk — state `@Observable` doesn't track. `MainMenuView` is also
  the `NavigationStack`'s persistent root, so popping back to it doesn't force
  a re-render on its own; the button kept showing whatever it last rendered.
  Fixed by making it a real `@State` var refreshed in `.onAppear`. Documented
  the general pattern in the `ios-hig` skill.
- Damage/heal amount field on the combatant detail screen was cramped next to
  the Damage/Heal buttons on narrow widths — amount field now gets its own
  full-width row, buttons on the row below

### Changed
- Renamed the "Combatants" preset-management menu entry/screen to **Creatures**
  — it manages reusable creature templates, not the actual combatants in a
  session, and shared the same word as the real thing was confusing. Icon
  changed from `person.3.fill` (implies literal humans) to `pawprint.fill`
  (reads as "creature" generically — goblins, skeletons, wolves, whatever)
- Creature presets now also carry an **Initiative Bonus** (flat modifier added
  to random 1–20 rolls only, never on top of an explicit value) — edited from
  Main Menu → Creatures, applied silently when adding a combatant whose name
  matches a preset. `CombatSession.addCombatant`/`addCombatants` both take an
  `initiativeBonus: Int = 0` parameter now
- Four more generic starter creatures: Orc, Wolf, Zombie, Guard (alongside the
  existing Goblin/Skeleton/Thief), each with HP + initiative bonus researched
  for realism, described only in our own generic terms
- Load Session: removed the extra confirmation dialog on delete — swipe-to-
  reveal + tap Delete is already two deliberate actions

### Added
- **HP tracking**: opt-in per combatant (`maxHP`/`currentHP` on `Combatant`),
  damage/heal controls and a "Track HP" prompt on the detail screen, HP shown
  in the list row colored by remaining fraction, and a "Dead" badge/skull icon
  + dimmed row when HP hits 0 (combatant stays in turn order, not auto-removed)
- **Round counter**: `CombatSession.roundNumber`, increments when turn order
  wraps to the first combatant, reverts correctly via Previous Turn, shown both
  in the toolbar and as plain centered text above the combatant list
- **Editable session name**: the combat screen's title is now a text field
  bound to `session.name`; blank input is ignored. Default name shortened to a
  short-form date (was overflowing the toolbar and squeezing out the round
  counter)
- **Remove combatant**: swipe left + confirm, matching the pattern already used
  for sessions; adjusts `currentTurnIndex` correctly and clears turn-revert
  history (a reverted-to snapshot could otherwise resurrect a removed combatant)
- **Add-combatant modal**: replaced the inline card row (too easy to trigger by
  an accidental tap outside it, and too fiddly to hit the small per-field
  controls) with a plain "Add Combatant" tap target at the *bottom* of the list
  that opens a native `Form` sheet — full-size rows for Name/Initiative/Max
  HP/Count
- **Creature presets**: adding a combatant auto-saves/updates a `CreaturePreset`
  by name (`PresetStore`, no explicit save step) — typing a name that matches
  an existing preset auto-fills its HP. Three generic starter presets ship on
  first launch. Managed from a new Main Menu "Creatures" entry: edit name/HP,
  swipe to delete with confirmation
- Previous/Next Turn bar now uses Liquid Glass on iOS 26+ (`GlassEffectContainer`,
  `.glassProminent` for Next Turn, `.glass` for Previous Turn), gated with
  `#available(iOS 26.0, *)` and falling back to the existing themed bar below
  that. It's the only glass button in the app — went through every button and
  only this one qualifies as a floating control per Apple's guidance ("reserved
  for the navigation layer that floats above content"); documented the full
  reasoning in the `ios-hig` skill so future buttons get evaluated the same way

### Changed
- Main menu "Resume" button is now hidden entirely (not just disabled) when
  there's no session to resume, instead of showing a muted-but-still-visible
  button that did nothing when tapped
- Confirmed and documented: the app requests zero permissions (no usage-
  description keys, no entitlements, all storage local) and is already a
  universal build (`UIDeviceFamily` includes tablet) — see `SPEC.md`
- Renamed `Participant` → `Combatant` throughout the codebase (types, files, UI
  copy, docs) — confirmed with user; `ParticipantDetailView.swift` is now
  `CombatantDetailView.swift`
- Combatant name and initiative are now editable from the detail screen (bordered
  text fields bound directly to the session, matching the add-row style); the
  list re-sorts automatically since sort order is always computed fresh

### Planned
- HP tracking (opt-in per combatant) + a clear "dead" indicator when HP hits 0 —
  design written up in `SPEC.md` §5 ("HP Tracking"); not yet implemented, awaiting
  confirmation on the design before building

### Fixed
- Main menu "Resume" button could appear enabled (bold red, primary styling) while
  actually disabled, and would silently no-op if tapped in that state — this could
  happen if the tracked "last active session" pointer went stale (its file missing/
  unreadable). Fixed two ways: `SessionStore.resumableSession()` now self-heals by
  clearing the stale pointer the moment it can't load the record, and the Resume
  button only uses the bold "primary" styling when it's actually enabled (falls back
  to the same muted look as New Session/Load Session otherwise) so a disabled state
  can't be visually mistaken for a live one
- **App ran letterboxed (black bars top/bottom) on real devices.** Root cause:
  `GENERATE_INFOPLIST_FILE: YES` makes Xcode build Info.plist purely from
  `INFOPLIST_KEY_*` build settings — the target's `infoPlist:` dict in `project.yml`
  (launch screen, scene manifest, orientations) was silently ignored and never reached
  the built app, so iOS fell back to legacy letterboxed scaling. Replaced with
  `INFOPLIST_KEY_UILaunchScreen_Generation`/`INFOPLIST_KEY_UIApplicationSceneManifest_Generation`/
  `INFOPLIST_KEY_UISupportedInterfaceOrientations`, verified present in the built
  `.app`'s actual Info.plist this time (`plutil -p`), not just trusted from `project.yml`
- `AddEffectView` had overlapping content on smaller screens / with the target picker
  expanded — rewritten from a hand-rolled `VStack` to a native `Form`/`Section` layout,
  which scrolls and handles safe areas on its own

### Changed
- No more explicit "Save Session" step: every `CombatSession` now has a stable auto-
  generated identity (`id` + date-based `name`); autosave just overwrites that session's
  file, so it's discoverable under "Load Session" without a save button/name prompt
- "Load Session": swipe-to-delete now requires confirmation before deleting, and the
  empty state uses the native `ContentUnavailableView`
- Direction: new/reworked screens should prefer native iOS components (`Form`, `List`,
  system tint) over the custom `Theme` styling, for now — see `CLAUDE.md`

### Added
- Main menu (Resume / New Session / Load Session) as the app's launch screen,
  wired through a shared `NavigationStack` (`RootView.swift`)
- Session persistence: `SessionStore` (JSON-on-disk, one file per session, keyed by
  the session's stable id), `SessionRecord`, `CombatSession.reset()/makeRecord()/load()`
- `Combatant`/`Effect`/`DurationType` are now `Codable` (`DurationType` has a
  hand-written implementation since its associated-value cases can't synthesize)
- "Menu" button (top-left) on the combat screen; autosaves on leaving the screen or
  app backgrounding
- New `ios-hig` skill
- `SessionStoreTests` and new `CombatSession` reset/record tests (35 tests total)

### Fixed
- `DEVELOPMENT_TEAM` in `project.yml` was blank, so every `xcodegen generate`
  silently stripped code signing and broke device builds — set to the correct
  team ID (verified against Xcode's account records)
- `CombatantDetailView` was reachable via `NavigationLink` from a `ContentView`
  that had no `NavigationStack` ancestor of its own — fixed as part of introducing
  `RootView`'s app-wide stack

### Changed
- UI pass against Apple's Human Interface Guidelines (new `ios-hig` skill at
  the `ios-hig` skill): name/initiative are now separate bordered
  text boxes instead of borderless text floating in one row; add button moved
  fully outside the initiative box with clear spacing; bottom bar relabeled
  "Previous Turn"/"Next Turn" with chevrons on the correct (outer) sides
- Replaced the "Add Combatant" modal with an always-visible inline row pinned
  atop the combatant list — name + initiative fields, add via return key or the
  plus button; random 1–20 initiative still applies when left blank
- "Back" now reverts to the previous turn's full state (turn index, reactions,
  effects) via a session history stack, instead of just calling `nextTurn()` again
- Extracted all inline `Color(red:green:blue:)` literals into `Theme.swift`; bumped
  the accent color from muted rust to a more saturated red per feedback

### Added
- `CombatSession.previousTurn()` / `canGoToPreviousTurn`, backed by a snapshot
  history pushed on each `nextTurn()`
- `Theme.swift` — single source of truth for the old-paper color palette
- Combatant detail view, reaction toggle, and custom effect management
  (add/remove, all four duration types, target picker)
- `initiativeTests` XCTest target covering turn advancement, reaction reset,
  effect expiration, and turn-revert logic (23 tests)
- Initial SwiftUI iOS app scaffold with Xcode 15+ support
- XcodeGen project configuration for reproducible builds
- Starter ContentView with SwiftUI Preview
- Bundle ID: xyz.rudsvar.initiative, iOS 17+ deployment target
- Development documentation (CLAUDE.md, README.md)
