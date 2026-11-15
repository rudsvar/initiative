import Foundation

/// What an effect *is*, which decides only how it's worded and weighted — never
/// how it behaves. A condition is something wrong with you; a cooldown is
/// something you can't do yet. They expire identically, but "Breath Weapon"
/// shouldn't shout in the same colour as "Burning", so cooldown chips take the
/// quiet treatment the reaction marker already uses.
enum EffectKind: String, Codable {
    case condition
    case cooldown
}

/// Which edge of a turn something happens on.
enum TurnBoundary: String, Codable {
    case startOfTurn
    case endOfTurn
}

struct Effect: Identifiable, Codable {
    let id: UUID
    var name: String
    var durationType: DurationType
    var kind: EffectKind = .condition
    /// Internal marker for the "reaction used" effect (see Combatant.reactionUsed) —
    /// nil/false for every normal, user-created effect. Optional so old saved
    /// sessions (from before this existed) still decode.
    var isReactionMarker: Bool?
    /// The death-save tally, present only on the Dying effect. See `Combatant.deathSaves`.
    var deathSaves: DeathSaves?

    init(
        id: UUID = UUID(),
        name: String,
        durationType: DurationType,
        kind: EffectKind = .condition,
        isReactionMarker: Bool? = nil,
        deathSaves: DeathSaves? = nil
    ) {
        self.id = id
        self.name = name
        self.durationType = durationType
        self.kind = kind
        self.isReactionMarker = isReactionMarker
        self.deathSaves = deathSaves
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, durationType, kind, isReactionMarker, deathSaves
    }

    /// Hand-written for the same reason as `Combatant`'s: a synthesized decoder
    /// doesn't fall back to declared defaults, so a non-optional `kind` would
    /// break every saved session that predates it. Absent means `.condition`.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        durationType = try container.decode(DurationType.self, forKey: .durationType)
        kind = try container.decodeIfPresent(EffectKind.self, forKey: .kind) ?? .condition
        isReactionMarker = try container.decodeIfPresent(Bool.self, forKey: .isReactionMarker)
        deathSaves = try container.decodeIfPresent(DeathSaves.self, forKey: .deathSaves)
    }
}

/// Effects are always self-applied by the DM to a combatant (there's no "target's
/// turn" concept — if you want it to expire on someone else's turn, put it on them),
/// so duration is just start/end of the owner's own turn, optionally repeated across
/// several of their turns via `remainingTurns`.
///
/// Two of the cases don't count down at all, and research into how conditions
/// actually end says both are needed. The governing rule across tabletop systems
/// is that *a condition lasts until it is countered, or for a duration specified
/// by whatever imposed it* — duration belongs to the **source**, not the
/// condition. So no condition is inherently one shape, but there are three
/// shapes, and only one of them is a countdown:
///
/// - **A countdown** — the source said how long. Blinded, Deafened, most
///   area effects.
/// - **`untilRollSucceeds`** — rolled at a turn boundary. Frightened, Charmed,
///   Paralyzed, Stunned, Restrained, Poisoned tend this way.
/// - **`untilRemoved`** — countered by doing something about it, on no schedule
///   at all. Prone (stand up), Grappled (escape, *when you choose to act* — so a
///   turn-boundary prompt would nag about a roll you may not be attempting),
///   Unconscious (regain HP), Burning (put it out), Exhausted (rest). Six of the
///   sixteen standard conditions want this, so it isn't an edge case.
///
/// `untilRollSucceeds` is the exception that doesn't count down at all: it sits
/// there until the DM says a roll succeeded. A recharging ability and a
/// save-ends condition are the same thing seen from two sides — *at this
/// boundary, something gets rolled, and on a success this goes away* — and they
/// differ only in the verb, which `EffectKind` already carries. The app never
/// rolls and never evaluates; `hint` is free text (`"5–6 on a d6"`, `"DC 14
/// Con"`) shown in the prompt purely so the DM knows what they're rolling.
enum DurationType: Equatable, Codable {
    case untilStartOfTheirTurn(remainingTurns: Int)
    case untilEndOfTheirTurn(remainingTurns: Int)
    case untilRollSucceeds(at: TurnBoundary, hint: String?)
    case untilRemoved
    /// Counts down at the top of each round rather than on anyone's turn. Only
    /// meaningful for a round-anchored effect (`CombatSession.roundEffects`) —
    /// an effect on a combatant has that combatant's turns to key off, which is
    /// more precise.
    case forRounds(remaining: Int)

    var description: String {
        switch self {
        case .untilStartOfTheirTurn(let remaining):
            return remaining > 1 ? "Until start of their turn (\(remaining) turns)" : "Until start of their next turn"
        case .untilEndOfTheirTurn(let remaining):
            return remaining > 1 ? "Until end of their turn (\(remaining) turns)" : "Until end of their next turn"
        case .untilRollSucceeds(let boundary, let hint):
            let when = boundary == .startOfTurn ? "start" : "end"
            let what = hint.map { " (\($0))" } ?? ""
            return "Until a roll succeeds, at the \(when) of their turn\(what)"
        case .untilRemoved:
            return "Until removed"
        case .forRounds(let remaining):
            return remaining > 1 ? "For \(remaining) more rounds" : "Until the end of this round"
        }
    }

    /// True for durations that never tick down on their own — they wait on the DM.
    var awaitsRoll: Bool {
        if case .untilRollSucceeds = self { return true }
        return false
    }

    private enum Kind: String, Codable {
        // untilStartOfTargetTurn/untilEndOfTargetTurn kept only so old saved sessions
        // with target-based effects still decode — they collapse into the owner-turn
        // equivalent since the target concept no longer exists.
        case untilStartOfTheirTurn, untilEndOfTheirTurn, untilStartOfTargetTurn, untilEndOfTargetTurn
        case untilRollSucceeds, untilRemoved, forRounds
    }

    private enum CodingKeys: String, CodingKey {
        case kind, remainingTurns, boundary, hint
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let remaining = try container.decodeIfPresent(Int.self, forKey: .remainingTurns) ?? 1
        switch try container.decode(Kind.self, forKey: .kind) {
        case .untilStartOfTheirTurn, .untilStartOfTargetTurn:
            self = .untilStartOfTheirTurn(remainingTurns: remaining)
        case .untilEndOfTheirTurn, .untilEndOfTargetTurn:
            self = .untilEndOfTheirTurn(remainingTurns: remaining)
        case .untilRollSucceeds:
            self = .untilRollSucceeds(
                at: try container.decodeIfPresent(TurnBoundary.self, forKey: .boundary) ?? .startOfTurn,
                hint: try container.decodeIfPresent(String.self, forKey: .hint)
            )
        case .untilRemoved:
            self = .untilRemoved
        case .forRounds:
            self = .forRounds(remaining: remaining)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .untilStartOfTheirTurn(let remaining):
            try container.encode(Kind.untilStartOfTheirTurn, forKey: .kind)
            try container.encode(remaining, forKey: .remainingTurns)
        case .untilEndOfTheirTurn(let remaining):
            try container.encode(Kind.untilEndOfTheirTurn, forKey: .kind)
            try container.encode(remaining, forKey: .remainingTurns)
        case .untilRollSucceeds(let boundary, let hint):
            try container.encode(Kind.untilRollSucceeds, forKey: .kind)
            try container.encode(boundary, forKey: .boundary)
            try container.encodeIfPresent(hint, forKey: .hint)
        case .untilRemoved:
            try container.encode(Kind.untilRemoved, forKey: .kind)
        case .forRounds(let remaining):
            try container.encode(Kind.forRounds, forKey: .kind)
            try container.encode(remaining, forKey: .remainingTurns)
        }
    }
}
