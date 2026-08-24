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

    var color: Color {
        switch self {
        // Cool hues carry the categories that need to stand apart from the warm
        // scheme; restraint and ongoing stay inside it. None of the five may sit
        // near candle gold — a chip that reads as accent-colored competes with
        // the current-turn marker, which is the one thing gold is reserved for.
        case .sensory: return Color(red: 0.52, green: 0.60, blue: 0.66)
        case .mental: return Color(red: 0.66, green: 0.50, blue: 0.74)
        case .restraint: return Color(red: 0.68, green: 0.52, blue: 0.38)
        case .disabling: return Color(red: 0.38, green: 0.66, blue: 0.62)
        case .ongoing: return Theme.ember
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
