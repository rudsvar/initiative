import SwiftUI

/// Standard status conditions offered as quick-pick options in `AddEffectView`,
/// each with an SF Symbol + color for display. Plain generic English condition
/// names — not trademarked or ruleset-specific (single descriptive words like
/// "stunned" aren't ownable; see project history for the research behind this).
/// Icons are Apple's own SF Symbols, licensed for in-app UI use on Apple platforms.
struct StandardCondition: Identifiable {
    var id: String { name }
    let name: String
    let symbolName: String
    let category: ConditionCategory

    var color: Color { category.color }
}

/// What a condition *does to you*, which is also what its color encodes.
///
/// Colour here is information, not decoration. Every condition used to carry its
/// own hue picked to suit the word ("Poisoned" green, "Charmed" pink, "Stunned"
/// yellow…), which meant a row of four chips showed four unrelated saturated
/// colors and none of them told you anything you couldn't already read off the
/// label. Grouping into five categories means a glance at the color says which
/// *kind* of trouble a combatant is in — the thing you actually need mid-combat —
/// and keeps the palette small enough to sit inside the app's warm scheme.
enum ConditionCategory {
    /// Can't perceive properly, or can't be perceived.
    case sensory
    /// Will and emotion are compromised.
    case mental
    /// Body is held, pinned, or downed.
    case restraint
    /// Can't act at all, or barely.
    case disabling
    /// Something is actively getting worse each round.
    case ongoing

    /// The actual hues live in `ThemePalette` because they have to be retuned per
    /// theme — a color that sits comfortably beside candle gold can land right on
    /// top of cinnabar. What stays fixed across every palette is the constraint:
    /// none of the five may sit near `Theme.accent`, because a chip that reads as
    /// accent-colored competes with the current-turn marker, which is the one
    /// thing the accent is reserved for. `ThemePaletteTests` enforces that for
    /// all four palettes.
    var color: Color {
        switch self {
        case .sensory: return Theme.palette.conditionSensory
        case .mental: return Theme.palette.conditionMental
        case .restraint: return Theme.palette.conditionRestraint
        case .disabling: return Theme.palette.conditionDisabling
        case .ongoing: return Theme.palette.conditionOngoing
        }
    }
}

enum ConditionLibrary {
    static let all: [StandardCondition] = [
        StandardCondition(name: "Blinded", symbolName: "eye.slash.fill", category: .sensory),
        StandardCondition(name: "Deafened", symbolName: "ear.fill", category: .sensory),
        StandardCondition(name: "Invisible", symbolName: "circle.dashed", category: .sensory),

        StandardCondition(name: "Charmed", symbolName: "heart.fill", category: .mental),
        StandardCondition(name: "Frightened", symbolName: "exclamationmark.triangle.fill", category: .mental),

        StandardCondition(name: "Grappled", symbolName: "hand.raised.fill", category: .restraint),
        StandardCondition(name: "Restrained", symbolName: "link", category: .restraint),
        StandardCondition(name: "Prone", symbolName: "arrow.down.circle.fill", category: .restraint),

        StandardCondition(name: "Incapacitated", symbolName: "bolt.slash.fill", category: .disabling),
        StandardCondition(name: "Paralyzed", symbolName: "bolt.fill", category: .disabling),
        StandardCondition(name: "Stunned", symbolName: "star.fill", category: .disabling),
        StandardCondition(name: "Unconscious", symbolName: "moon.zzz.fill", category: .disabling),
        StandardCondition(name: "Exhausted", symbolName: "battery.25", category: .disabling),

        StandardCondition(name: "Poisoned", symbolName: "drop.fill", category: .ongoing),
        StandardCondition(name: "Burning", symbolName: "flame.fill", category: .ongoing),
        StandardCondition(name: "Bleeding", symbolName: "drop.triangle.fill", category: .ongoing),
    ]

    /// Case-insensitive lookup by name, for badges that display an existing
    /// `Effect` (which only stores a name string, not a reference back to the
    /// condition).
    static func matching(name: String) -> StandardCondition? {
        all.first { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }
    }
}
