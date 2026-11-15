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
/// palette it was designed against and wrong in all the others.
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
/// They all share the same *structure* — elevation ladder, hairline borders, one
/// accent per screen, five condition categories — and differ only in hue. That's
/// deliberate: the structure is what makes the app legible mid-combat, so it
/// isn't something a theme gets to opt out of.
///
/// Order matters: this is the order the picker lists them in, dark themes first,
/// so `allCases` is the running order and not an arbitrary one.
/// Two themes for colour-blind use. Good is blue, bad is orange, warning is yellow,
/// and info is teal, so no status pair depends on telling red from green. Each
/// status colour stays clear of the accent.
extension ThemePalette {
    static let colorblindDark = ThemePalette(
        background: Color(red: 0.10, green: 0.10, blue: 0.11),
        backgroundLift: Color(red: 0.15, green: 0.15, blue: 0.16),
        surface: Color(red: 0.17, green: 0.17, blue: 0.19),
        surfaceRaised: Color(red: 0.24, green: 0.24, blue: 0.26),
        border: Color(red: 0.38, green: 0.38, blue: 0.40),

        accent: Color(red: 0.95, green: 0.95, blue: 0.97),
        accentForeground: Color(red: 0.10, green: 0.10, blue: 0.11),

        textPrimary: Color(red: 0.96, green: 0.96, blue: 0.96),
        textSecondary: Color(red: 0.78, green: 0.78, blue: 0.80),
        textTertiary: Color(red: 0.58, green: 0.58, blue: 0.60),
        placeholderText: Color(red: 0.66, green: 0.66, blue: 0.68),

        statusGood: Color(red: 0.34, green: 0.71, blue: 0.91),
        statusWarn: Color(red: 0.94, green: 0.89, blue: 0.26),
        statusBad: Color(red: 0.90, green: 0.50, blue: 0.20),
        statusNeutral: Color(red: 0.55, green: 0.55, blue: 0.57),
        statusInfo: Color(red: 0.00, green: 0.62, blue: 0.45),

        conditionSensory: Color(red: 0.34, green: 0.71, blue: 0.91),
        conditionMental: Color(red: 0.80, green: 0.48, blue: 0.65),
        conditionRestraint: Color(red: 0.90, green: 0.62, blue: 0.00),
        conditionDisabling: Color(red: 0.30, green: 0.75, blue: 0.60),
        conditionOngoing: Color(red: 0.60, green: 0.60, blue: 0.62),

        colorScheme: .dark
    )

    static let colorblindLight = ThemePalette(
        background: Color(red: 0.80, green: 0.80, blue: 0.79),
        backgroundLift: Color(red: 0.86, green: 0.86, blue: 0.85),
        surface: Color(red: 0.91, green: 0.91, blue: 0.90),
        surfaceRaised: Color(red: 0.99, green: 0.99, blue: 0.98),
        border: Color(red: 0.62, green: 0.62, blue: 0.62),

        accent: Color(red: 0.12, green: 0.12, blue: 0.12),
        accentForeground: Color(red: 0.97, green: 0.97, blue: 0.96),

        textPrimary: Color(red: 0.08, green: 0.08, blue: 0.08),
        textSecondary: Color(red: 0.30, green: 0.30, blue: 0.30),
        textTertiary: Color(red: 0.40, green: 0.40, blue: 0.40),
        placeholderText: Color(red: 0.50, green: 0.50, blue: 0.50),

        statusGood: Color(red: 0.00, green: 0.45, blue: 0.70),
        statusWarn: Color(red: 0.62, green: 0.52, blue: 0.00),
        statusBad: Color(red: 0.84, green: 0.37, blue: 0.00),
        statusNeutral: Color(red: 0.50, green: 0.50, blue: 0.50),
        statusInfo: Color(red: 0.00, green: 0.48, blue: 0.36),

        conditionSensory: Color(red: 0.00, green: 0.45, blue: 0.70),
        conditionMental: Color(red: 0.66, green: 0.30, blue: 0.50),
        conditionRestraint: Color(red: 0.80, green: 0.50, blue: 0.00),
        conditionDisabling: Color(red: 0.00, green: 0.48, blue: 0.36),
        conditionOngoing: Color(red: 0.30, green: 0.30, blue: 0.32),

        colorScheme: .light
    )
}

enum ThemeIdentifier: String, CaseIterable, Identifiable, Codable {
    case tavernCandlelight
    case inkAndCinnabar
    case slateAndBrass
    case verdigris
    case abyssal
    case nightshade
    case highContrast
    case parchment
    case vellum
    case colorblindDark
    case colorblindLight

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tavernCandlelight: return "Tavern Candlelight"
        case .inkAndCinnabar: return "Ink & Cinnabar"
        case .slateAndBrass: return "Slate & Brass"
        case .verdigris: return "Verdigris"
        case .abyssal: return "Abyssal"
        case .nightshade: return "Nightshade"
        case .highContrast: return "High Contrast"
        case .parchment: return "Parchment"
        case .vellum: return "Vellum"
        case .colorblindDark: return "Colour-blind Dark"
        case .colorblindLight: return "Colour-blind Light"
        }
    }

    var tagline: String {
        switch self {
        case .tavernCandlelight: return "A dark room lit by one warm flame."
        case .inkAndCinnabar: return "Cool black page, warm paper ink, one red mark."
        case .slateAndBrass: return "Cold stone and worn brass. Quiet and legible."
        case .verdigris: return "Damp stone and oxidised copper."
        case .abyssal: return "Deep water. Cold dark, one cold light."
        case .nightshade: return "Violet-black, and something luminous in it."
        case .highContrast: return "Maximum legibility. For bad light and tired eyes."
        case .parchment: return "Light. Printed-page black on warm paper."
        case .vellum: return "Light and cool. Grey paper, deep teal ink."
        case .colorblindDark: return "Blue for good, orange for bad. No red-green pairs."
        case .colorblindLight: return "The same colour-blind-safe pairs on a light page."
        }
    }

    /// Whether the theme is built for a lit room or a dark one. Used to group the
    /// picker, since that's the first thing a person is actually choosing.
    var isLight: Bool { palette.colorScheme == .light }

    var palette: ThemePalette {
        switch self {
        case .tavernCandlelight: return .tavernCandlelight
        case .inkAndCinnabar: return .inkAndCinnabar
        case .slateAndBrass: return .slateAndBrass
        case .verdigris: return .verdigris
        case .abyssal: return .abyssal
        case .nightshade: return .nightshade
        case .highContrast: return .highContrast
        case .parchment: return .parchment
        case .vellum: return .vellum
        case .colorblindDark: return .colorblindDark
        case .colorblindLight: return .colorblindLight
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

    /// Damp stone and oxidised copper. The green accent is the point: with a cool
    /// grey-green ground, an accent from the same family but far more saturated
    /// reads as *the metal in the wall* rather than as a colour laid on top.
    /// `conditionDisabling` gives up its usual teal here — teal is the accent's
    /// own neighbourhood — and takes magenta instead.
    static let verdigris = ThemePalette(
        background: Color(red: 0.085, green: 0.098, blue: 0.095),
        backgroundLift: Color(red: 0.115, green: 0.132, blue: 0.128),
        surface: Color(red: 0.128, green: 0.146, blue: 0.142),
        surfaceRaised: Color(red: 0.178, green: 0.200, blue: 0.194),
        border: Color(red: 0.31, green: 0.345, blue: 0.335),

        accent: Color(red: 0.36, green: 0.78, blue: 0.66),
        accentForeground: Color(red: 0.05, green: 0.060, blue: 0.058),

        textPrimary: Color(red: 0.92, green: 0.94, blue: 0.93),
        textSecondary: Color(red: 0.70, green: 0.74, blue: 0.72),
        textTertiary: Color(red: 0.50, green: 0.535, blue: 0.52),
        placeholderText: Color(red: 0.58, green: 0.615, blue: 0.60),

        statusGood: Color(red: 0.56, green: 0.72, blue: 0.36),
        statusWarn: Color(red: 0.90, green: 0.62, blue: 0.24),
        statusBad: Color(red: 0.86, green: 0.32, blue: 0.30),
        statusNeutral: Color(red: 0.53, green: 0.56, blue: 0.55),
        statusInfo: Color(red: 0.44, green: 0.60, blue: 0.80),

        conditionSensory: Color(red: 0.52, green: 0.60, blue: 0.72),
        conditionMental: Color(red: 0.68, green: 0.50, blue: 0.82),
        conditionRestraint: Color(red: 0.78, green: 0.56, blue: 0.36),
        conditionDisabling: Color(red: 0.86, green: 0.44, blue: 0.62),
        conditionOngoing: Color(red: 0.88, green: 0.48, blue: 0.20),

        colorScheme: .dark
    )

    /// Deep water: a blue-black that keeps getting bluer as it lifts, and one
    /// cold bioluminescent light. The only palette whose accent is *colder* than
    /// its ground — worth having precisely because every other theme here warms
    /// up to mark the current turn.
    static let abyssal = ThemePalette(
        background: Color(red: 0.055, green: 0.075, blue: 0.098),
        backgroundLift: Color(red: 0.082, green: 0.108, blue: 0.138),
        surface: Color(red: 0.095, green: 0.122, blue: 0.155),
        surfaceRaised: Color(red: 0.135, green: 0.170, blue: 0.212),
        border: Color(red: 0.28, green: 0.33, blue: 0.40),

        accent: Color(red: 0.34, green: 0.78, blue: 0.86),
        accentForeground: Color(red: 0.04, green: 0.055, blue: 0.07),

        textPrimary: Color(red: 0.90, green: 0.93, blue: 0.96),
        textSecondary: Color(red: 0.68, green: 0.73, blue: 0.79),
        textTertiary: Color(red: 0.48, green: 0.53, blue: 0.60),
        placeholderText: Color(red: 0.56, green: 0.61, blue: 0.68),

        statusGood: Color(red: 0.40, green: 0.70, blue: 0.44),
        statusWarn: Color(red: 0.92, green: 0.64, blue: 0.24),
        statusBad: Color(red: 0.88, green: 0.34, blue: 0.40),
        statusNeutral: Color(red: 0.52, green: 0.56, blue: 0.62),
        statusInfo: Color(red: 0.58, green: 0.60, blue: 0.90),

        conditionSensory: Color(red: 0.60, green: 0.66, blue: 0.78),
        conditionMental: Color(red: 0.66, green: 0.50, blue: 0.90),
        conditionRestraint: Color(red: 0.76, green: 0.58, blue: 0.42),
        conditionDisabling: Color(red: 0.52, green: 0.84, blue: 0.52),
        conditionOngoing: Color(red: 0.92, green: 0.50, blue: 0.34),

        colorScheme: .dark
    )

    /// Violet-black with a luminous green in it. Green is the complement of the
    /// ground rather than a brighter version of it, which is what stops the
    /// accent disappearing into the scheme the way a magenta accent would here.
    /// `conditionMental` is pushed hard toward pink for the same reason — violet
    /// is the *room's* colour in this palette, so a violet chip says nothing.
    static let nightshade = ThemePalette(
        background: Color(red: 0.078, green: 0.062, blue: 0.098),
        backgroundLift: Color(red: 0.108, green: 0.088, blue: 0.135),
        surface: Color(red: 0.122, green: 0.100, blue: 0.152),
        surfaceRaised: Color(red: 0.190, green: 0.160, blue: 0.232),
        border: Color(red: 0.33, green: 0.29, blue: 0.39),

        accent: Color(red: 0.60, green: 0.85, blue: 0.40),
        accentForeground: Color(red: 0.05, green: 0.040, blue: 0.065),

        textPrimary: Color(red: 0.94, green: 0.92, blue: 0.96),
        textSecondary: Color(red: 0.73, green: 0.70, blue: 0.78),
        textTertiary: Color(red: 0.53, green: 0.50, blue: 0.58),
        placeholderText: Color(red: 0.61, green: 0.58, blue: 0.66),

        statusGood: Color(red: 0.36, green: 0.72, blue: 0.62),
        statusWarn: Color(red: 0.92, green: 0.62, blue: 0.22),
        statusBad: Color(red: 0.88, green: 0.30, blue: 0.42),
        statusNeutral: Color(red: 0.56, green: 0.53, blue: 0.60),
        statusInfo: Color(red: 0.48, green: 0.62, blue: 0.86),

        conditionSensory: Color(red: 0.54, green: 0.62, blue: 0.76),
        conditionMental: Color(red: 0.80, green: 0.56, blue: 0.90),
        conditionRestraint: Color(red: 0.80, green: 0.58, blue: 0.40),
        conditionDisabling: Color(red: 0.42, green: 0.72, blue: 0.80),
        conditionOngoing: Color(red: 0.92, green: 0.42, blue: 0.52),

        colorScheme: .dark
    )

    /// Pure black, pure white, saturated everything. Not a mood — a legibility
    /// setting, for a badly lit table or tired eyes. It's the one palette that
    /// deliberately breaks the "muted, warm versions of red/green/blue" house
    /// rule, because muting is exactly what it's trading away; borders are
    /// stronger here too, since at this contrast an edge is information rather
    /// than decoration.
    static let highContrast = ThemePalette(
        background: Color(red: 0.0, green: 0.0, blue: 0.0),
        backgroundLift: Color(red: 0.055, green: 0.055, blue: 0.055),
        surface: Color(red: 0.105, green: 0.105, blue: 0.105),
        surfaceRaised: Color(red: 0.20, green: 0.20, blue: 0.20),
        border: Color(red: 0.55, green: 0.55, blue: 0.55),

        accent: Color(red: 1.00, green: 0.85, blue: 0.20),
        accentForeground: Color(red: 0.0, green: 0.0, blue: 0.0),

        textPrimary: Color(red: 1.0, green: 1.0, blue: 1.0),
        textSecondary: Color(red: 0.85, green: 0.85, blue: 0.85),
        textTertiary: Color(red: 0.68, green: 0.68, blue: 0.68),
        placeholderText: Color(red: 0.75, green: 0.75, blue: 0.75),

        statusGood: Color(red: 0.30, green: 0.95, blue: 0.45),
        statusWarn: Color(red: 1.00, green: 0.55, blue: 0.10),
        statusBad: Color(red: 1.00, green: 0.35, blue: 0.35),
        statusNeutral: Color(red: 0.70, green: 0.70, blue: 0.70),
        statusInfo: Color(red: 0.40, green: 0.75, blue: 1.00),

        conditionSensory: Color(red: 0.55, green: 0.80, blue: 1.00),
        conditionMental: Color(red: 0.85, green: 0.55, blue: 1.00),
        conditionRestraint: Color(red: 1.00, green: 0.65, blue: 0.45),
        conditionDisabling: Color(red: 0.30, green: 0.95, blue: 0.85),
        conditionOngoing: Color(red: 1.00, green: 0.45, blue: 0.60),

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

extension ThemePalette {
    /// Light but cool — grey paper and deep teal ink, where Parchment is warm
    /// paper and oxblood. Two light themes earn their place because the choice
    /// between them isn't decorative: paper white and screen white read as
    /// different materials, and which one a room's lighting flatters varies.
    static let vellum = ThemePalette(
        background: Color(red: 0.855, green: 0.862, blue: 0.868),
        backgroundLift: Color(red: 0.895, green: 0.902, blue: 0.908),
        surface: Color(red: 0.922, green: 0.928, blue: 0.934),
        surfaceRaised: Color(red: 0.988, green: 0.991, blue: 0.995),
        border: Color(red: 0.66, green: 0.672, blue: 0.685),

        accent: Color(red: 0.06, green: 0.36, blue: 0.42),
        accentForeground: Color(red: 0.96, green: 0.975, blue: 0.98),

        textPrimary: Color(red: 0.10, green: 0.108, blue: 0.118),
        textSecondary: Color(red: 0.30, green: 0.315, blue: 0.335),
        textTertiary: Color(red: 0.44, green: 0.455, blue: 0.478),
        placeholderText: Color(red: 0.50, green: 0.515, blue: 0.538),

        statusGood: Color(red: 0.16, green: 0.44, blue: 0.18),
        statusWarn: Color(red: 0.64, green: 0.44, blue: 0.04),
        statusBad: Color(red: 0.72, green: 0.16, blue: 0.14),
        statusNeutral: Color(red: 0.42, green: 0.435, blue: 0.45),
        statusInfo: Color(red: 0.20, green: 0.30, blue: 0.68),

        conditionSensory: Color(red: 0.32, green: 0.38, blue: 0.60),
        conditionMental: Color(red: 0.44, green: 0.24, blue: 0.58),
        conditionRestraint: Color(red: 0.50, green: 0.34, blue: 0.12),
        // Magenta rather than the usual teal: teal *is* the accent here.
        conditionDisabling: Color(red: 0.58, green: 0.20, blue: 0.42),
        conditionOngoing: Color(red: 0.38, green: 0.44, blue: 0.08),

        colorScheme: .light
    )
}
