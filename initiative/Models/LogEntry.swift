import Foundation

/// A structured HP change underlying a log entry's display text. Entries that carry
/// one of these can be deleted from the log — deleting recomputes the affected
/// combatant's current/max HP from scratch by replaying the remaining HP-operation
/// entries for just that combatant, in order. So every change to HP needs one,
/// or the replay would quietly drop it. Entries without one (turn changes,
/// combatant added/removed, effects) aren't deletable — there's no defined
/// "undo" for them yet.
enum HPOperation: Codable, Equatable {
    case enableTracking(amount: Int)
    case damage(amount: Int)
    case healing(amount: Int)
    case maxHPIncrease(amount: Int)
    /// Lowers max HP (to a floor of 0, which is death) and current HP with it if needed.
    case maxHPDecrease(amount: Int)
    /// Direct corrections typed over a value: no absorption, no stacking rules.
    case setCurrentHP(value: Int)
    case setMaxHP(value: Int)
    case setTemporaryHP(value: Int)
    /// Grants temporary hit points, replacing whatever was there. Replayable like
    /// the rest — temporary HP has to be part of the log or deleting a damage
    /// entry would recompute current HP without the buffer that absorbed it.
    case grantTemporaryHP(amount: Int)
    /// A heal past max that goes above it: current HP fills to max and the rest
    /// becomes temporary HP, replacing any there was.
    case healAboveMax(amount: Int)
    /// Temporary HP taken off by hand, never real hit points. Added 2026-11-19;
    /// earlier builds logged it as `damage`, which `LogEntry` migrates on load.
    case lowerTemporaryHP(amount: Int)
    /// Kill: tracked HP drops to 0.
    case kill
    /// Revive, or a natural 20 on a death save: back to at least 1 HP.
    case revive
}

struct LogEntry: Identifiable, Codable {
    let id: UUID
    var text: String
    var timestamp: Date
    var roundNumber: Int
    var combatantId: UUID?
    var hpOperation: HPOperation?

    /// Whether this entry can be swiped away in the log UI.
    var isDeletable: Bool { hpOperation != nil }

    init(
        id: UUID = UUID(),
        text: String,
        timestamp: Date = Date(),
        roundNumber: Int,
        combatantId: UUID? = nil,
        hpOperation: HPOperation? = nil
    ) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.roundNumber = roundNumber
        self.combatantId = combatantId
        self.hpOperation = hpOperation
    }

    private enum CodingKeys: String, CodingKey {
        case id, text, timestamp, roundNumber, combatantId, hpOperation
    }

    /// Written by hand for one migration: builds before 2026-11-19 logged
    /// temporary HP taken off by hand as `damage`. Replayed as damage it hits real
    /// HP once an earlier grant is deleted, so it loads as `lowerTemporaryHP`.
    /// Those entries are recognised by the text that build wrote for them.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        text = try container.decode(String.self, forKey: .text)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        roundNumber = try container.decode(Int.self, forKey: .roundNumber)
        combatantId = try container.decodeIfPresent(UUID.self, forKey: .combatantId)
        hpOperation = try container.decodeIfPresent(HPOperation.self, forKey: .hpOperation)
        if case .damage(let amount) = hpOperation, Self.isLegacyTemporaryHPLoss(text) {
            hpOperation = .lowerTemporaryHP(amount: amount)
        }
    }

    /// "Wren lost 2 temporary HP (3 left)" or "Wren lost all temporary HP".
    private static func isLegacyTemporaryHPLoss(_ text: String) -> Bool {
        text.range(of: #"^.+ lost (\d+ temporary HP \(\d+ left\)|all temporary HP)$"#, options: .regularExpression) != nil
    }
}
