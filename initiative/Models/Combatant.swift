import Foundation

struct Combatant: Identifiable, Codable {
    let id: UUID
    var name: String
    var initiative: Int
    var effects: [Effect] = []
    var maxHP: Int?
    var currentHP: Int?
    var armorClass: Int?
    /// A buffer taken off before real hit points. Not healing: it doesn't refill,
    /// isn't capped by `maxHP`, and once spent it's gone.
    var temporaryHP: Int?
    /// A bonus on armor class for this fight, like temporary HP: replaced by a new
    /// grant, not stacked, removed by hand, and never copied back to the library.
    /// Counted in `effectiveArmorClass`.
    var temporaryAC: Int?
    /// The armor class in play: base plus any temporary AC. Nil when AC isn't tracked.
    var effectiveArmorClass: Int? {
        armorClass.map { $0 + (temporaryAC ?? 0) }
    }

    /// Net change to current HP since this combatant's turn last started (damage is
    /// negative, healing positive). Shown beside current HP, cleared at turn start.
    var recentHPChange: Int?
    /// Set by Kill for a combatant with no HP tracked. Nil otherwise.
    var markedDead: Bool?
    /// Net change to max HP since this combatant's turn last started.
    var recentMaxHPChange: Int?
    /// Net change to armor class since this combatant's turn last started.
    var recentACChange: Int?

    /// Set once `CombatSession.increaseMaxHP` has ever raised this combatant's
    /// ceiling (a buff, a level-up mid-fight). Drives bolding the Max readout in
    /// the compact health row — a plain HP edit through the max-HP field doesn't
    /// set it, since that's correcting a number rather than boosting it.
    var maxHPIncreased: Bool = false

    /// Whether this is one of the party rather than something they're fighting.
    ///
    /// Only death saves use it today (an NPC at 0 HP is simply dead; a player
    /// starts rolling), but it's a property of the combatant rather than a flag
    /// on that feature because it's the same distinction player view will want in
    /// order to hide the monsters' numbers and not the party's.
    var isPlayer: Bool = false

    /// Something the combatant is actively holding — no name, no duration, just
    /// on or off. Taking damage while this is true threatens it and raises a
    /// check; see `CombatSession.applyDamage`. Deliberately not an `Effect`: it
    /// carries no configuration of its own, so a stored name/duration would be
    /// clutter with nothing to say.
    var isConcentrating: Bool = false

    /// Countable resources like Legendary Actions — see `LimitedUse`. Resets to
    /// full at the start of this combatant's own turn, same rule as `Reaction`.
    var limitedUses: [LimitedUse] = []

    /// The death-save tally, held by the Dying effect. Setting it adds, updates or
    /// removes that effect, so the rest of the app reads and writes one value.
    /// Nil until the combatant starts dying. See `DeathSaves`.
    var deathSaves: DeathSaves? {
        get { effects.first { $0.deathSaves != nil }?.deathSaves }
        set {
            guard let newValue else {
                effects.removeAll { $0.deathSaves != nil }
                return
            }
            if let index = effects.firstIndex(where: { $0.deathSaves != nil }) {
                effects[index].deathSaves = newValue
            } else {
                effects.append(Effect(name: "Dying", durationType: .untilRemoved, deathSaves: newValue))
            }
        }
    }

    /// Reaction tracking is implemented as a regular effect (untilStartOfTheirTurn,
    /// marked internal) rather than its own stored field, so it expires through the
    /// same removeExpiredEffects mechanism as everything else instead of needing a
    /// bespoke reset step in CombatSession.nextTurn(). See CombatSession.toggleReaction.
    var reactionUsed: Bool {
        effects.contains { $0.isReactionMarker == true }
    }

    /// Effects meant for user-facing display. Excludes the internal reaction marker,
    /// and the Dying effect once its tally is resolved: stabilised and dead have
    /// their own marks, so a "Dying" chip would contradict them.
    var visibleEffects: [Effect] {
        effects.filter { effect in
            if effect.isReactionMarker == true { return false }
            if let saves = effect.deathSaves, saves.isResolved { return false }
            return true
        }
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
        guard let currentHP else { return markedDead == true }
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

    /// The one key that no longer exists as a stored property, read only when loading old saves.
    private enum LegacyKeys: String, CodingKey {
        case deathSaves
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, initiative, effects, maxHP, currentHP, armorClass, temporaryHP, temporaryAC, recentHPChange, recentMaxHPChange, markedDead, recentACChange, isPlayer, isConcentrating, limitedUses, maxHPIncreased
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
        temporaryHP = try container.decodeIfPresent(Int.self, forKey: .temporaryHP)
        temporaryAC = try container.decodeIfPresent(Int.self, forKey: .temporaryAC)
        recentHPChange = try container.decodeIfPresent(Int.self, forKey: .recentHPChange)
        markedDead = try container.decodeIfPresent(Bool.self, forKey: .markedDead)
        recentMaxHPChange = try container.decodeIfPresent(Int.self, forKey: .recentMaxHPChange)
        recentACChange = try container.decodeIfPresent(Int.self, forKey: .recentACChange)
        isPlayer = try container.decodeIfPresent(Bool.self, forKey: .isPlayer) ?? false
        isConcentrating = try container.decodeIfPresent(Bool.self, forKey: .isConcentrating) ?? false
        limitedUses = try container.decodeIfPresent([LimitedUse].self, forKey: .limitedUses) ?? []
        // Saves from before the Dying effect carried the tally on the combatant itself.
        // Move it onto a Dying effect so it keeps working.
        let legacyKeys = try decoder.container(keyedBy: LegacyKeys.self)
        if let legacy = try legacyKeys.decodeIfPresent(DeathSaves.self, forKey: .deathSaves) {
            deathSaves = legacy
        }
        maxHPIncreased = try container.decodeIfPresent(Bool.self, forKey: .maxHPIncreased) ?? false
    }
}
