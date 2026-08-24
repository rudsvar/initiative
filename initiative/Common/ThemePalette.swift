import SwiftUI

/// Every color the app draws, as a value that can be swapped at runtime.
///
/// `Theme` is the façade views read from; this is what sits behind it. Splitting
/// the *values* out from the *vocabulary* is what makes theme selection possible
/// without touching a single call site: views keep saying `Theme.surface`, and
/// which surface that is becomes a property of the selected palette.
///
/// A palette is a complete set — there are no optional or defaulted fields on
/// purpose. Adding a token means every palette has to answer for it, which is the
/// only reliable way to stop a new color from silently looking correct in the
/// palette it was designed against and wrong in the other three.
struct ThemePalette: Equatable {

    // MARK: - Surfaces
    //
    // An elevation ladder, not one flat tone: background -> surface ->
    // surfaceRaised. Each step is a visible lift, so a row reads as sitting on
    // the page and an input as sitting in the row without a border saying so.
    // In light palettes the ladder still runs *toward the light* (paper gets
    // cleaner and whiter as it comes forward), which is why it can't simply be
    // inverted from a dark palette.

    let background: Color
    /// Top of `Theme.backgroundGradient` — light falling from above.
    let backgroundLift: Color
    let surface: Color
    let surfaceRaised: Color
    /// Card outlines and separators, always drawn at `Theme.hairline` weight.
    let border: Color

    // MARK: - Accent

    /// The palette's one saturated color, spent on at most one thing per screen.
    let accent: Color
    /// Text/glyph color for content sitting *on* an accent fill. Not derivable
    /// from `background`: a light palette's accent is dark, so its accent
    /// foreground has to go the other way.
    let accentForeground: Color

    // MARK: - Text

    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    /// SwiftUI's plain `TextField("placeholder", text:)` renders its placeholder
    /// in a fixed system gray regardless of theme; the `TextField(text:label:)`
    /// form is needed to override it with this.
    let placeholderText: Color

    // MARK: - Semantic status

    let statusGood: Color
    let statusWarn: Color
    let statusBad: Color
    let statusNeutral: Color
    let statusInfo: Color

    // MARK: - Condition categories
    //
    // See `ConditionCategory` for what each one means. They live in the palette
    // rather than next to the conditions because they have to be retuned per
    // scheme: a hue that sits comfortably beside candle gold can land right on
    // top of cinnabar, and every one of them has to stay clear of `accent`
    // (enforced by `ThemePaletteTests`).

    let conditionSensory: Color
    let conditionMental: Color
    let conditionRestraint: Color
    let conditionDisabling: Color
    let conditionOngoing: Color

    // MARK: - System appearance

    /// Which system appearance the palette is built for, forced app-wide so every
    /// system-provided color (native toolbar chrome, `Form`/`List` defaults,
    /// keyboard, selection highlights) follows the palette instead of the
    /// device's own light/dark setting.
    let colorScheme: ColorScheme
}

// MARK: - The palettes

/// The selectable themes. Each is a complete `ThemePalette` plus the name and
/// one-line description shown in the appearance picker.
///
/// All four share the same *structure* — elevation ladder, hairline borders, one
/// accent per screen, five condition categories — and differ only in hue. That's
/// deliberate: the structure is what makes the app legible mid-combat, so it
/// isn't something a theme gets to opt out of.
enum ThemeIdentifier: String, CaseIterable, Identifiable, Codable {
    case tavernCandlelight
    case inkAndCinnabar
    case slateAndBrass
    case parchment

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tavernCandlelight: return "Tavern Candlelight"
        case .inkAndCinnabar: return "Ink & Cinnabar"
        case .slateAndBrass: return "Slate & Brass"
        case .parchment: return "Parchment"
        }
    }

    var tagline: String {
        switch self {
        case .tavernCandlelight: return "A dark room lit by one warm flame."
        case .inkAndCinnabar: return "Cool black page, warm paper ink, one red mark."
        case .slateAndBrass: return "Cold stone and worn brass. Quiet and legible."
        case .parchment: return "Light. Printed-page black on warm paper."
        }
    }

    var palette: ThemePalette {
        switch self {
        case .tavernCandlelight: return .tavernCandlelight
        case .inkAndCinnabar: return .inkAndCinnabar
        case .slateAndBrass: return .slateAndBrass
        case .parchment: return .parchment
        }
    }
}

extension ThemePalette {

    /// The original. A dark room lit by one candle: warm near-black ink, warm
    /// brown surfaces, candle gold reserved for the current turn.
    static let tavernCandlelight = ThemePalette(
        background: Color(red: 0.11, green: 0.085, blue: 0.072),
        backgroundLift: Color(red: 0.165, green: 0.128, blue: 0.104),
        surface: Color(red: 0.175, green: 0.135, blue: 0.110),
        surfaceRaised: Color(red: 0.235, green: 0.180, blue: 0.145),
        border: Color(red: 0.36, green: 0.28, blue: 0.225),

        accent: Color(red: 0.85, green: 0.64, blue: 0.25),
        accentForeground: Color(red: 0.11, green: 0.085, blue: 0.072),

        textPrimary: Color(red: 0.95, green: 0.92, blue: 0.86),
        textSecondary: Color(red: 0.76, green: 0.68, blue: 0.58),
        textTertiary: Color(red: 0.56, green: 0.48, blue: 0.41),
        placeholderText: Color(red: 0.66, green: 0.57, blue: 0.48),

        statusGood: Color(red: 0.56, green: 0.68, blue: 0.38),
        // Orange, not amber. Amber is the obvious "warning" hue and was the
        // original choice, but in a gold-accent palette it lands within 0.09 of
        // the accent itself — a "Wounded" band in the row next to the
        // current-turn numeral was reading as a second current turn.
        statusWarn: Color(red: 0.89, green: 0.45, blue: 0.15),
        statusBad: Color(red: 0.78, green: 0.32, blue: 0.26),
        statusNeutral: Color(red: 0.55, green: 0.50, blue: 0.46),
        statusInfo: Color(red: 0.42, green: 0.56, blue: 0.62),

        conditionSensory: Color(red: 0.52, green: 0.60, blue: 0.66),
        conditionMental: Color(red: 0.66, green: 0.50, blue: 0.74),
        conditionRestraint: Color(red: 0.68, green: 0.52, blue: 0.38),
        conditionDisabling: Color(red: 0.38, green: 0.66, blue: 0.62),
        conditionOngoing: Color(red: 0.80, green: 0.36, blue: 0.22),

        colorScheme: .dark
    )

    /// Cool blue-black ground, warm off-white text, a single cinnabar accent.
    /// The cool-ground/warm-ink contrast is a printed-page relationship rather
    /// than a screen one, which is what lets it carry the serif without reading
    /// as "fantasy app". Red is a rarer accent than gold and already means
    /// urgency, which is exactly what a current-turn marker is — so here
    /// `conditionOngoing` moves to a cold acid green rather than staying warm,
    /// to keep red meaning one thing only.
    static let inkAndCinnabar = ThemePalette(
        background: Color(red: 0.075, green: 0.077, blue: 0.082),
        backgroundLift: Color(red: 0.105, green: 0.108, blue: 0.116),
        surface: Color(red: 0.118, green: 0.121, blue: 0.130),
        surfaceRaised: Color(red: 0.165, green: 0.170, blue: 0.182),
        border: Color(red: 0.30, green: 0.31, blue: 0.335),

        accent: Color(red: 0.83, green: 0.31, blue: 0.20),
        accentForeground: Color(red: 0.06, green: 0.062, blue: 0.066),

        textPrimary: Color(red: 0.93, green: 0.92, blue: 0.895),
        textSecondary: Color(red: 0.70, green: 0.71, blue: 0.73),
        textTertiary: Color(red: 0.50, green: 0.51, blue: 0.545),
        placeholderText: Color(red: 0.58, green: 0.59, blue: 0.62),

        statusGood: Color(red: 0.44, green: 0.70, blue: 0.52),
        statusWarn: Color(red: 0.88, green: 0.68, blue: 0.30),
        // Magenta rather than red: "critical" must not read as the accent, and
        // when the accent *is* red it has to go a long way to get clear of it.
        statusBad: Color(red: 0.80, green: 0.24, blue: 0.56),
        statusNeutral: Color(red: 0.52, green: 0.53, blue: 0.56),
        statusInfo: Color(red: 0.44, green: 0.60, blue: 0.72),

        conditionSensory: Color(red: 0.48, green: 0.58, blue: 0.66),
        conditionMental: Color(red: 0.62, green: 0.48, blue: 0.78),
        // Clay rather than the bronze the warm palettes use: bronze and this
        // palette's acid-green "ongoing" are near-neighbours in RGB.
        conditionRestraint: Color(red: 0.72, green: 0.50, blue: 0.46),
        conditionDisabling: Color(red: 0.34, green: 0.66, blue: 0.64),
        conditionOngoing: Color(red: 0.66, green: 0.74, blue: 0.32),

        colorScheme: .dark
    )

    /// Desaturated blue-grey stone with worn brass. The quiet one — least
    /// flavour, most legible, and the one that sits most comfortably next to
    /// Apple's own apps.
    static let slateAndBrass = ThemePalette(
        background: Color(red: 0.105, green: 0.115, blue: 0.125),
        backgroundLift: Color(red: 0.140, green: 0.152, blue: 0.165),
        surface: Color(red: 0.148, green: 0.160, blue: 0.173),
        surfaceRaised: Color(red: 0.195, green: 0.210, blue: 0.226),
        border: Color(red: 0.33, green: 0.355, blue: 0.38),

        accent: Color(red: 0.76, green: 0.62, blue: 0.36),
        accentForeground: Color(red: 0.105, green: 0.115, blue: 0.125),

        textPrimary: Color(red: 0.91, green: 0.925, blue: 0.94),
        textSecondary: Color(red: 0.68, green: 0.71, blue: 0.745),
        textTertiary: Color(red: 0.48, green: 0.51, blue: 0.55),
        placeholderText: Color(red: 0.56, green: 0.59, blue: 0.63),

        statusGood: Color(red: 0.48, green: 0.70, blue: 0.52),
        // Pushed toward orange: plain amber sits right on top of brass.
        statusWarn: Color(red: 0.90, green: 0.48, blue: 0.20),
        statusBad: Color(red: 0.82, green: 0.34, blue: 0.32),
        statusNeutral: Color(red: 0.54, green: 0.57, blue: 0.60),
        statusInfo: Color(red: 0.44, green: 0.62, blue: 0.74),

        conditionSensory: Color(red: 0.50, green: 0.62, blue: 0.72),
        conditionMental: Color(red: 0.64, green: 0.50, blue: 0.80),
        // Dusty clay rather than the bronze the other dark palettes use —
        // bronze is indistinguishable from this palette's brass accent.
        conditionRestraint: Color(red: 0.68, green: 0.46, blue: 0.50),
        conditionDisabling: Color(red: 0.36, green: 0.64, blue: 0.62),
        conditionOngoing: Color(red: 0.84, green: 0.34, blue: 0.26),

        colorScheme: .dark
    )

    /// The contrarian one: warm paper, near-black serif, one oxblood accent.
    /// Nothing about a light fantasy tool reads as generated, because dark is the
    /// default assumption — but a white phone at a dimly lit table is a
    /// flashlight in everyone's face, so this is offered, never the default.
    ///
    /// Note the ladder direction: `background` is the *darkest* step here and
    /// `surfaceRaised` the lightest, so raised things still come toward the
    /// light rather than away from it.
    static let parchment = ThemePalette(
        // The steps are spread wider apart than in the dark palettes: near the
        // top of the range, equal-sized numeric steps compress into almost no
        // visible difference, so a ladder that looks generous on paper values
        // can still read as one flat sheet.
        background: Color(red: 0.868, green: 0.838, blue: 0.778),
        backgroundLift: Color(red: 0.905, green: 0.880, blue: 0.826),
        surface: Color(red: 0.928, green: 0.908, blue: 0.860),
        surfaceRaised: Color(red: 0.995, green: 0.988, blue: 0.970),
        border: Color(red: 0.68, green: 0.645, blue: 0.575),

        accent: Color(red: 0.58, green: 0.13, blue: 0.15),
        accentForeground: Color(red: 0.97, green: 0.955, blue: 0.92),

        textPrimary: Color(red: 0.13, green: 0.115, blue: 0.10),
        textSecondary: Color(red: 0.34, green: 0.31, blue: 0.27),
        textTertiary: Color(red: 0.46, green: 0.43, blue: 0.38),
        placeholderText: Color(red: 0.52, green: 0.49, blue: 0.44),

        // Darkened across the board: a status color has to hold its own against
        // paper, where the mid-tones that work on black wash out completely.
        statusGood: Color(red: 0.24, green: 0.45, blue: 0.22),
        statusWarn: Color(red: 0.66, green: 0.50, blue: 0.06),
        statusBad: Color(red: 0.78, green: 0.33, blue: 0.08),
        statusNeutral: Color(red: 0.45, green: 0.42, blue: 0.38),
        statusInfo: Color(red: 0.22, green: 0.40, blue: 0.52),

        conditionSensory: Color(red: 0.30, green: 0.40, blue: 0.50),
        conditionMental: Color(red: 0.44, green: 0.26, blue: 0.58),
        conditionRestraint: Color(red: 0.46, green: 0.36, blue: 0.14),
        conditionDisabling: Color(red: 0.10, green: 0.42, blue: 0.40),
        conditionOngoing: Color(red: 0.36, green: 0.48, blue: 0.06),

        colorScheme: .light
    )
}
