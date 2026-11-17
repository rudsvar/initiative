import Foundation

/// A structured HP change underlying a log entry's display text. Entries that carry
/// one of these can be deleted from the log — deleting recomputes the affected
/// combatant's current/max HP from scratch by replaying the remaining HP-operation
/// entries for just that combatant, in order. Entries without one (turn changes,
/// combatant added/removed, deaths) aren't deletable — there's no defined "undo"
/// for them yet.
enum HPOperation: Codable, Equatable {
    case enableTracking(amount: Int)
    case damage(amount: Int)
    case healing(amount: Int)
    case maxHPIncrease(amount: Int)
    /// Lowers max HP (to a floor of 0, which is death) and current HP with it if needed.
    case maxHPDecrease(amount: Int)
    /// Grants temporary hit points, replacing whatever was there. Replayable like
    /// the rest — temporary HP has to be part of the log or deleting a damage
    /// entry would recompute current HP without the buffer that absorbed it.
    case grantTemporaryHP(amount: Int)
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
}
