import SwiftUI

/// The single source of truth for this app's look: color, spacing, corner radius
/// and type. Every screen reads from here rather than relying on system defaults
/// (`Form`/`List` are white by default and need an explicit `Theme.background` +
/// `.scrollContentBackground(.hidden)` — see `ContentView` for the pattern).
///
/// **Tavern Candlelight.** The organising idea is a dark room lit by one warm
/// light source: an almost-black warm ink base, surfaces that get progressively
/// lighter the "closer" they are to the reader, and a single candle-gold accent
/// that is the only saturated color in normal use. That restraint is deliberate —
/// gold only reads as light if almost nothing else competes with it, so accent is
/// spent on exactly one thing per screen (the current turn, the primary action)
/// and everything else is carried by surface level and type.
enum Theme {

    // MARK: - Surfaces
    //
    // A genuine elevation ladder rather than one flat tone. Each step is a
    // visible lift, so a row reads as sitting on the page and an input as sitting
    // in the row without needing a border to say so.

    /// The dark room — the base every screen paints first.
    static let background = Color(red: 0.11, green: 0.085, blue: 0.072)
    /// Top of `backgroundGradient`: light falling from above, not a flat wash.
    static let backgroundLift = Color(red: 0.165, green: 0.128, blue: 0.104)
    /// Cards and list rows.
    static let surface = Color(red: 0.175, green: 0.135, blue: 0.110)
    /// Inputs, chips, and the current-turn row — the topmost step.
    static let surfaceRaised = Color(red: 0.235, green: 0.180, blue: 0.145)

    /// Warm vertical falloff applied to full-screen backgrounds. Very low
    /// contrast on purpose: enough to stop the screen reading as a flat block,
    /// not enough to be noticed as "a gradient".
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundLift, background],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Separators and card outlines. Used at hairline weight (`Theme.hairline`) —
    /// a full 1pt stroke at full opacity is what makes a UI read as "boxes drawn
    /// around things" instead of surfaces.
    static let border = Color(red: 0.36, green: 0.28, blue: 0.225)
    static let hairline: CGFloat = 0.75

    /// Kept as the name older code and `SelectAllTextField` already use.
    static var divider: Color { border }
    static var inputBackground: Color { surfaceRaised }

    // MARK: - Accent

    /// Candle gold. The app's one saturated color — see the type doc above.
    static let accent = Color(red: 0.85, green: 0.64, blue: 0.25)
    /// Gold at fill strength, for tinted backgrounds that must not shout.
    static var accentSoft: Color { accent.opacity(0.14) }
    /// Warm secondary for destructive/urgent affordances, so "danger" stays in
    /// the same warm family instead of importing a foreign system red.
    static let ember = Color(red: 0.80, green: 0.36, blue: 0.22)

    // MARK: - Text

    static let textPrimary = Color(red: 0.95, green: 0.92, blue: 0.86)
    static let textSecondary = Color(red: 0.76, green: 0.68, blue: 0.58)
    static let textTertiary = Color(red: 0.56, green: 0.48, blue: 0.41)
    /// SwiftUI's plain `TextField("placeholder", text:)` always renders its
    /// placeholder in a fixed system gray, ignoring the app theme entirely; the
    /// `TextField(text:label:)` form is needed to override it with this color.
    static let placeholderText = Color(red: 0.66, green: 0.57, blue: 0.48)

    // MARK: - Semantic status

    static let statusGood = Color(red: 0.56, green: 0.68, blue: 0.38)
    static let statusWarn = Color(red: 0.87, green: 0.58, blue: 0.24)
    static let statusBad = Color(red: 0.78, green: 0.32, blue: 0.26)
    static let statusNeutral = Color(red: 0.55, green: 0.50, blue: 0.46)
    static let statusInfo = Color(red: 0.42, green: 0.56, blue: 0.62)
}

// MARK: - System chrome

extension Theme {
    /// Paints the navigation bar with the app's own surface color and serif
    /// titles. `.preferredColorScheme(.dark)` alone leaves the bar on UIKit's
    /// neutral system gray, which reads as a foreign slab against this palette's
    /// warm brown — and there's no SwiftUI-level way to set a nav bar background
    /// color, so it has to go through UIAppearance. Called once from `RootView`'s
    /// initializer, before any bar exists.
    static func applyNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(backgroundLift)
        appearance.shadowColor = UIColor(border.opacity(0.5))

        let serifTitle = UIFont.preferredFont(forTextStyle: .headline).serif
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(textPrimary),
            .font: serifTitle,
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(textPrimary),
            .font: UIFont.preferredFont(forTextStyle: .largeTitle).serif,
        ]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
}

// MARK: - Spacing

extension Theme {
    /// A 4pt scale. Every gap and inset in the app comes from here — ad-hoc
    /// numbers are what make spacing look almost-but-not-quite aligned.
    enum Spacing {
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
    /// All styles are built on Dynamic Type text styles (`.headline`, `.caption`,
    /// …) rather than fixed point sizes so they still scale with the user's text
    /// size setting.
    enum Typography {
        static let display = Font.system(.largeTitle, design: .serif).weight(.bold)
        static let title = Font.system(.title2, design: .serif).weight(.semibold)
        /// Names in list rows.
        static let rowTitle = Font.system(.headline, design: .serif)
        static let body = Font.system(.subheadline)
        static let bodyEmphasis = Font.system(.subheadline).weight(.semibold)
        static let caption = Font.system(.caption)
        /// Small all-caps field/section labels — see `View.sectionLabel()`.
        static let label = Font.system(.caption2).weight(.semibold)

        /// Tabular figures at a text style's size, for stat readouts (HP, AC).
        static let stat = Font.system(.caption, design: .rounded).monospacedDigit()
        static let statLarge = Font.system(.title3, design: .rounded).weight(.bold).monospacedDigit()

        /// Tabular figures at an explicit size, for the display-sized numerals
        /// (the initiative column) where a text style isn't large enough.
        static func numeric(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
            .system(size: size, weight: weight, design: .rounded).monospacedDigit()
        }
    }
}
