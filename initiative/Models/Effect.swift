import Foundation

struct Effect: Identifiable, Codable {
    let id: UUID
    var name: String
    var durationType: DurationType
    /// Internal marker for the "reaction used" effect (see Combatant.reactionUsed) —
    /// nil/false for every normal, user-created effect. Optional so old saved
    /// sessions (from before this existed) still decode.
    var isReactionMarker: Bool?

    init(id: UUID = UUID(), name: String, durationType: DurationType, isReactionMarker: Bool? = nil) {
        self.id = id
        self.name = name
        self.durationType = durationType
        self.isReactionMarker = isReactionMarker
    }
}

/// Effects are always self-applied by the DM to a combatant (there's no "target's
/// turn" concept — if you want it to expire on someone else's turn, put it on them),
/// so duration is just start/end of the owner's own turn, optionally repeated across
/// several of their turns via `remainingTurns`.
enum DurationType: Equatable, Codable {
    case untilStartOfTheirTurn(remainingTurns: Int)
    case untilEndOfTheirTurn(remainingTurns: Int)

    var description: String {
        switch self {
        case .untilStartOfTheirTurn(let remaining):
            return remaining > 1 ? "Until start of their turn (\(remaining) turns)" : "Until start of their next turn"
        case .untilEndOfTheirTurn(let remaining):
            return remaining > 1 ? "Until end of their turn (\(remaining) turns)" : "Until end of their next turn"
        }
    }

    private enum Kind: String, Codable {
        // untilStartOfTargetTurn/untilEndOfTargetTurn kept only so old saved sessions
        // with target-based effects still decode — they collapse into the owner-turn
        // equivalent since the target concept no longer exists.
        case untilStartOfTheirTurn, untilEndOfTheirTurn, untilStartOfTargetTurn, untilEndOfTargetTurn
    }

    private enum CodingKeys: String, CodingKey {
        case kind, remainingTurns
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let remaining = try container.decodeIfPresent(Int.self, forKey: .remainingTurns) ?? 1
        switch try container.decode(Kind.self, forKey: .kind) {
        case .untilStartOfTheirTurn, .untilStartOfTargetTurn:
            self = .untilStartOfTheirTurn(remainingTurns: remaining)
        case .untilEndOfTheirTurn, .untilEndOfTargetTurn:
            self = .untilEndOfTheirTurn(remainingTurns: remaining)
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
        }
    }
}
