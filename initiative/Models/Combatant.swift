import Foundation

struct Combatant: Identifiable, Codable {
    let id: UUID
    var name: String
    var initiative: Int
    var effects: [Effect] = []
    var maxHP: Int?
    var currentHP: Int?
    var armorClass: Int?

    /// Whether this is one of the party rather than something they're fighting.
    ///
    /// Only death saves use it today (an NPC at 0 HP is simply dead; a player
    /// starts rolling), but it's a property of the combatant rather than a flag
    /// on that feature because it's the same distinction player view will want in
    /// order to hide the monsters' numbers and not the party's.
    var isPlayer: Bool = false

    /// Non-nil once this combatant has started dying. See `DeathSaves`.
    var deathSaves: DeathSaves?

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

    /// Down but not out: rolling death saves, neither stabilised nor dead.
    var isDying: Bool {
        guard let deathSaves else { return false }
        return !deathSaves.isResolved
    }

    /// At 0 HP and stabilised — no longer rolling, and explicitly not dead.
    var isStabilised: Bool {
        deathSaves?.isStable == true
    }

    /// Only meaningful once HP tracking is enabled (maxHP/currentHP non-nil).
    ///
    /// Once death saves are in play they decide this instead of the HP value:
    /// a dying or stabilised combatant sits at 0 HP without being dead, which is
    /// the whole point of the mechanic.
    var isDead: Bool {
        if let deathSaves { return deathSaves.isDead }
        guard let currentHP else { return false }
        return currentHP <= 0
    }

    init(
        id: UUID = UUID(),
        name: String,
        initiative: Int,
        maxHP: Int? = nil,
        armorClass: Int? = nil,
        isPlayer: Bool = false
    ) {
        self.id = id
        self.name = name
        self.initiative = initiative
        self.maxHP = maxHP
        self.currentHP = maxHP
        self.armorClass = armorClass
        self.isPlayer = isPlayer
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case id, name, initiative, effects, maxHP, currentHP, armorClass, isPlayer, deathSaves
    }

    /// Written out by hand rather than synthesized: Swift's synthesized decoding
    /// does **not** fall back to a property's declared default when the key is
    /// missing, so adding a non-optional field would stop every previously saved
    /// session from decoding. Saved sessions are a durable on-disk format (see
    /// `CodableCompatibilityTests`), so new fields decode as absent —
    /// `isPlayer` false, meaning a combatant saved before the distinction existed
    /// is treated as an NPC and behaves exactly as it did.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        initiative = try container.decode(Int.self, forKey: .initiative)
        effects = try container.decodeIfPresent([Effect].self, forKey: .effects) ?? []
        maxHP = try container.decodeIfPresent(Int.self, forKey: .maxHP)
        currentHP = try container.decodeIfPresent(Int.self, forKey: .currentHP)
        armorClass = try container.decodeIfPresent(Int.self, forKey: .armorClass)
        isPlayer = try container.decodeIfPresent(Bool.self, forKey: .isPlayer) ?? false
        deathSaves = try container.decodeIfPresent(DeathSaves.self, forKey: .deathSaves)
    }
}
