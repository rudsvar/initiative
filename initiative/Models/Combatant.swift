import Foundation

struct Combatant: Identifiable, Codable {
    let id: UUID
    var name: String
    var initiative: Int
    var effects: [Effect] = []
    var maxHP: Int?
    var currentHP: Int?
    var armorClass: Int?

    /// Reaction tracking is implemented as a regular effect (untilStartOfTheirTurn,
    /// marked internal) rather than its own stored field, so it expires through the
    /// same removeExpiredEffects mechanism as everything else instead of needing a
    /// bespoke reset step in CombatSession.nextTurn(). See CombatSession.toggleReaction.
    var reactionUsed: Bool {
        effects.contains { $0.isReactionMarker == true }
    }

    /// Effects meant for user-facing display — excludes the internal reaction marker.
    var visibleEffects: [Effect] {
        effects.filter { $0.isReactionMarker != true }
    }

    /// Only meaningful once HP tracking is enabled (maxHP/currentHP non-nil).
    var isDead: Bool {
        guard let currentHP else { return false }
        return currentHP <= 0
    }

    init(id: UUID = UUID(), name: String, initiative: Int, maxHP: Int? = nil, armorClass: Int? = nil) {
        self.id = id
        self.name = name
        self.initiative = initiative
        self.maxHP = maxHP
        self.currentHP = maxHP
        self.armorClass = armorClass
    }
}
