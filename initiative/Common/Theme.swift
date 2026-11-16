import SwiftUI

/// The single source of truth for this app's look: color, spacing, corner radius
/// and type. Every screen reads from here rather than relying on system defaults
/// (`Form`/`List` are white by default and need an explicit `Theme.background` +
/// `.scrollContentBackground(.hidden)` — see `ContentView` for the pattern).
///
/// **This type is a vocabulary, not a set of values.** The colors themselves live
/// in `ThemePalette` and the user picks between four of them (see
/// `ThemeIdentifier`); `Theme`'s color accessors just forward to whichever is
/// selected. Views never name a palette — they say `Theme.surface`, and get
/// re-rendered automatically when the selection changes (see `ThemeController`
/// for why that works without threading anything through the environment).
///
/// The *structure* is not themeable, and that's the point. Whichever palette is
/// in force:
///
/// - Surfaces come from an elevation ladder (`background` → `surface` →
///   `surfaceRaised`), never from borders.
/// - Borders are hairline weight (`Theme.hairline`). A full 1pt stroke at full
///   opacity is what makes a UI read as "boxes drawn around things".
/// - `accent` marks **at most one thing per screen** — the current turn, the
///   primary action. An accent only reads as emphasis if nothing competes with
///   it, so anything else that needs to stand out uses a status or condition
///   color instead.
/// - Serif for anything that names something, tabular figures for anything
///   numeric (see `Typography`).
enum Theme {

    /// The palette currently in force. Prefer the named accessors below; this is
    /// for the appearance picker, which genuinely needs whole palettes.
    static var palette: ThemePalette { ThemeController.shared.palette }

    // MARK: - Surfaces

    static var background: Color { palette.background }
    static var backgroundLift: Color { palette.backgroundLift }
    static var surface: Color { palette.surface }
    static var surfaceRaised: Color { palette.surfaceRaised }

    /// Vertical falloff applied to full-screen backgrounds. Very low contrast on
    /// purpose: enough to stop the screen reading as a flat block, not enough to
    /// be noticed as "a gradient".
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundLift, background],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var border: Color { palette.border }
    static let hairline: CGFloat = 0.75

    // MARK: - Accent

    static var accent: Color { palette.accent }
    /// Text/glyphs sitting on top of an accent fill.
    static var accentForeground: Color { palette.accentForeground }
    /// Accent at fill strength, for tinted backgrounds that must not shout.
    static var accentSoft: Color { accent.opacity(0.14) }

    // MARK: - Text

    static var textPrimary: Color { palette.textPrimary }
    static var textSecondary: Color { palette.textSecondary }
    static var textTertiary: Color { palette.textTertiary }
    static var placeholderText: Color { palette.placeholderText }

    // MARK: - Semantic status

    static var statusGood: Color { palette.statusGood }
    static var statusWarn: Color { palette.statusWarn }
    static var statusBad: Color { palette.statusBad }
    static var statusNeutral: Color { palette.statusNeutral }
    static var statusInfo: Color { palette.statusInfo }

    /// The swipe-to-delete red. Deliberately the same in every theme, so delete
    /// always reads as delete; it is not a palette colour and is not themed.
    static let deleteAction = Color(red: 0.84, green: 0.22, blue: 0.20)

    // MARK: - System appearance

    /// Forced app-wide from `RootView` so every system-provided color follows the
    /// palette instead of the device's own light/dark setting.
    static var colorScheme: ColorScheme { palette.colorScheme }
}

// MARK: - System chrome

extension Theme {
    /// Paints the navigation bar with the app's own surface color and serif
    /// titles. `.preferredColorScheme` alone leaves the bar on UIKit's neutral
    /// system gray, which reads as a foreign slab against any of these palettes —
    /// and there's no SwiftUI-level way to set a nav bar background color, so it
    /// has to go through UIAppearance.
    ///
    /// Called once from `RootView.init` and again from `ThemeController` on every
    /// theme change. The re-application matters: `UINavigationBar.appearance()`
    /// only configures bars created *after* it is set, and by the time anyone
    /// picks a theme the app's bar already exists — so live bars are updated in
    /// place too.
    static func applyNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        // Below iOS 26: opaque, painted in the app's own surface color —
        // `.preferredColorScheme` alone leaves the bar on UIKit's neutral
        // system gray, and there's no plain SwiftUI way to recolor it.
        //
        // iOS 26+: transparent instead, so the system's native floating
        // Liquid Glass bar shows through and list content is visible
        // scrolling up underneath it, the way every other iOS 26 app's title
        // bar behaves — an opaque custom background would paint over that
        // and make the bar look like a flat pre-26 slab despite running on
        // glass hardware. Title text keeps the app's own serif/color even
        // here; only the *backdrop* defers to the system.
        if #available(iOS 26.0, *) {
            appearance.configureWithTransparentBackground()
        } else {
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(backgroundLift)
            appearance.shadowColor = UIColor(border.opacity(0.5))
        }

        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(textPrimary),
            .font: UIFont.preferredFont(forTextStyle: .headline).serif,
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(textPrimary),
            .font: UIFont.preferredFont(forTextStyle: .largeTitle).serif,
        ]

        // Pins the `.searchable` field's text to the system's own default
        // search font up front. Without this it briefly inherits the
        // surrounding nav bar's custom serif title font from this same
        // appearance proxy on first layout, then gets corrected to the
        // system's plain body font a frame later — visible as the search
        // field's text doing a tiny resize/font-swap right as the screen
        // appears. Search fields are one thing this app leaves fully native
        // (see `Common/SearchBar.swift`), so this just makes that consistent
        // from frame one instead of after a visible correction.
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).font = .preferredFont(forTextStyle: .body)

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance

        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                window.applyToNavigationBars(appearance)
            }
        }
    }
}

private extension UIView {
    /// Depth-first walk applying a bar appearance to every live `UINavigationBar`
    /// in the hierarchy. SwiftUI owns its bars and exposes no handle to them, so
    /// finding them by traversal is the only way to restyle one that already
    /// exists.
    func applyToNavigationBars(_ appearance: UINavigationBarAppearance) {
        if let bar = self as? UINavigationBar {
            bar.standardAppearance = appearance
            bar.scrollEdgeAppearance = appearance
            bar.compactAppearance = appearance
            bar.setNeedsLayout()
        }
        for subview in subviews {
            subview.applyToNavigationBars(appearance)
        }
    }
}

// MARK: - Spacing

extension Theme {
    /// A 4pt scale. Every gap and inset in the app comes from here — ad-hoc
    /// numbers are what make spacing look almost-but-not-quite aligned.
    enum Spacing {
        /// Half-step, for gaps *inside* a single element (the two lines of a stat
        /// column) where a full step would read as separating them.
        static let xxs: CGFloat = 2
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 10
        static let lg: CGFloat = 14
    }
}

// MARK: - Type

extension Theme {
    /// The app's typographic voice: a serif for anything that names something
    /// (screen titles, combatant and creature names) and rounded monospaced
    /// digits for anything numeric. The serif is what gives the app a character
    /// of its own rather than reading as default-SF-everywhere; the monospaced
    /// digits are functional — initiative, HP and AC sit in columns, and
    /// proportional digits make those columns visibly jitter between values.
    ///
    /// Text styles are built on Dynamic Type (`.headline`, `.caption`, …) rather
    /// than fixed point sizes so they scale with the user's text size setting.
    enum Typography {
        static let display = Font.system(.largeTitle, design: .serif).weight(.bold)
        static let title = Font.system(.title2, design: .serif).weight(.semibold)
        /// Names in list rows.
        static let rowTitle = Font.system(.headline, design: .serif)
        static let body = Font.system(.subheadline)
        static let bodyEmphasis = Font.system(.subheadline).weight(.semibold)
        static let caption = Font.system(.caption)
        /// Small all-caps field/section labels — see `Text.sectionLabel()`.
        static let label = Font.system(.caption2).weight(.semibold)
        /// The smallest text: the dying tally's circles.
        static let micro = Font.system(.caption2)
        /// The dying tally's circles, small enough that two rows fit the name's line.
        static let tally = Font.system(size: 8)
        /// The dying mark, the height of the name.
        static let skull = Font.system(size: 18)

        /// Tabular figures at a text style's size, for stat readouts (HP, AC).
        static let stat = Font.system(.caption, design: .rounded).monospacedDigit()
        /// The number in a stat readout (HP, AC, initiative bonus). One size for every
        /// readout in the app, on library rows and the roster alike.
        static let readout = Font.system(.callout, design: .rounded).weight(.semibold).monospacedDigit()
        /// The symbol above it, scaling with the number.
        static let readoutIcon = Font.system(.caption)
        static let statLarge = Font.system(.headline, design: .rounded).weight(.bold).monospacedDigit()
        /// A glyph that sits inline with adjacent text (the heart beside an HP
        /// value, the skull beside a name). A text style rather than a point size
        /// so it grows with the text it's sitting next to.
        static let iconInline = Font.system(.caption2)

        /// Tabular figures at an explicit size, for the display-sized numerals
        /// (the initiative column) where a text style isn't large enough.
        static func numeric(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
            .system(size: size, weight: weight, design: .rounded).monospacedDigit()
        }

        // SF Symbol sizes. Fixed points rather than text styles because each of
        // these sits in a fixed-size frame or circle — letting the glyph scale
        // inside a frame that doesn't would just clip it.
        /// Glyph inside a status chip.
        static let iconChip = Font.system(size: 11)
        /// Chevrons and small close/dismiss controls.
        static let iconControl = Font.system(size: 12, weight: .semibold)
        /// Leading icon on a menu or list row.
        static let iconRow = Font.system(size: 15)
        /// Leading icon on a row that is itself an action (reaction toggle).
        static let iconRowProminent = Font.system(size: 17)
        /// Glyph in a circular action button (the HP steppers).
        static let iconAction = Font.system(size: 16, weight: .bold)
        /// The one oversized glyph on a screen — the bottom bar's add button.
        static let iconPrimaryAction = Font.system(size: 26, weight: .bold)
    }
}
