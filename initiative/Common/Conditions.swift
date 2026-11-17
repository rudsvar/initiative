import SwiftUI

/// Standard status conditions offered as one-tap chips on the combatant screen,
/// each with an SF Symbol + color for display. Plain generic English condition
/// names — not trademarked or ruleset-specific (single descriptive words like
/// "stunned" aren't ownable; see project history for the research behind this).
/// Icons are Apple's own SF Symbols, licensed for in-app UI use on Apple platforms.
struct StandardCondition: Identifiable {
    var id: String { name }
    let name: String
    let symbolName: String
    let category: ConditionCategory
    /// How this condition *usually* ends, used to prefill the duration when it's
    /// picked so the common case needs no further tapping.
    ///
    /// Research note: no condition is inherently one shape — the governing rule
    /// is that a condition lasts until it's countered or for a duration the
    /// *source* specified, so duration belongs to the source, not the condition.
    /// These are tendencies, always overridable, and they exist so that picking
    /// "Prone" doesn't pre-select a countdown when standing up is what ends it.
    let defaultDuration: DurationType

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
    /// every palette.
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
        StandardCondition(name: "Blinded", symbolName: "eye.slash.fill", category: .sensory, defaultDuration: .untilEndOfTheirTurn(remainingTurns: 1)),
        StandardCondition(name: "Deafened", symbolName: "ear.fill", category: .sensory, defaultDuration: .untilEndOfTheirTurn(remainingTurns: 1)),
        StandardCondition(name: "Invisible", symbolName: "circle.dashed", category: .sensory, defaultDuration: .untilRemoved),

        StandardCondition(name: "Charmed", symbolName: "heart.fill", category: .mental, defaultDuration: .untilRollSucceeds(at: .endOfTurn, hint: nil)),
        StandardCondition(name: "Frightened", symbolName: "exclamationmark.triangle.fill", category: .mental, defaultDuration: .untilRollSucceeds(at: .endOfTurn, hint: nil)),

        StandardCondition(name: "Grappled", symbolName: "hand.raised.fill", category: .restraint, defaultDuration: .untilRemoved),
        StandardCondition(name: "Restrained", symbolName: "link", category: .restraint, defaultDuration: .untilRollSucceeds(at: .endOfTurn, hint: nil)),
        StandardCondition(name: "Prone", symbolName: "arrow.down.circle.fill", category: .restraint, defaultDuration: .untilRemoved),

        StandardCondition(name: "Incapacitated", symbolName: "bolt.slash.fill", category: .disabling, defaultDuration: .untilEndOfTheirTurn(remainingTurns: 1)),
        StandardCondition(name: "Paralyzed", symbolName: "bolt.fill", category: .disabling, defaultDuration: .untilRollSucceeds(at: .endOfTurn, hint: nil)),
        StandardCondition(name: "Stunned", symbolName: "star.fill", category: .disabling, defaultDuration: .untilRollSucceeds(at: .endOfTurn, hint: nil)),
        StandardCondition(name: "Unconscious", symbolName: "moon.zzz.fill", category: .disabling, defaultDuration: .untilRemoved),
        StandardCondition(name: "Exhausted", symbolName: "battery.25", category: .disabling, defaultDuration: .untilRemoved),

        StandardCondition(name: "Poisoned", symbolName: "drop.fill", category: .ongoing, defaultDuration: .untilRollSucceeds(at: .endOfTurn, hint: nil)),
        StandardCondition(name: "Burning", symbolName: "flame.fill", category: .ongoing, defaultDuration: .untilRemoved),
        StandardCondition(name: "Bleeding", symbolName: "drop.triangle.fill", category: .ongoing, defaultDuration: .untilEndOfTheirTurn(remainingTurns: 1)),
    ]

    /// Case-insensitive lookup by name, for badges that display an existing
    /// `Effect` (which only stores a name string, not a reference back to the
    /// condition).
    static func matching(name: String) -> StandardCondition? {
        all.first { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }
    }
}

extension Combatant {
    /// Effects that are not standard conditions: cooldowns and ones the DM named.
    /// The detail screen lists these with a remove button and an editor. Dying is
    /// left out: its tally belongs to the death-save flow, and removing or
    /// re-timing it there would drop the tally or add a second roll.
    var customEffects: [Effect] {
        visibleEffects.filter { $0.deathSaves == nil && ConditionLibrary.matching(name: $0.name) == nil }
    }
}

/// How an effect looks, decided once for the roster chip, the effect row and the
/// cooldown chip.
extension Effect {
    var symbolName: String {
        if deathSaves != nil { return "heart.slash.fill" }
        switch kind {
        case .cooldown: return Self.cooldownSymbol(for: durationType)
        case .condition: return ConditionLibrary.matching(name: name)?.symbolName ?? "sparkles"
        }
    }

    /// Never the accent, which marks the current turn. A cooldown is something
    /// you can't do yet rather than something wrong with you, so it is quiet; a
    /// custom effect is quiet too, as it has no category to colour it.
    var tint: Color {
        if deathSaves != nil { return Theme.statusBad }
        switch kind {
        case .cooldown: return Theme.textTertiary
        case .condition: return ConditionLibrary.matching(name: name)?.color ?? Theme.textSecondary
        }
    }

    /// An hourglass while a roll is owed, a clock while it counts down.
    static func cooldownSymbol(for duration: DurationType) -> String {
        duration.awaitsRoll ? "hourglass" : "clock"
    }
}
