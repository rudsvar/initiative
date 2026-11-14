import Foundation

/// A named resource with a countable number of uses — Legendary Actions, a
/// "3/day" ability — that a DM spends down over the fight rather than toggling
/// on and off like a condition, or waiting on a single roll like a cooldown.
///
/// Resets to `total` when the round turns over (`CombatSession.resetLimitedUses`),
/// not on the owning combatant's own turn like `Reaction` — a Legendary Action
/// budget reads more naturally as "this many per round" than "this many by the
/// time your turn comes back around".
struct LimitedUse: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var total: Int
    var remaining: Int

    init(id: UUID = UUID(), name: String, total: Int, remaining: Int? = nil) {
        self.id = id
        self.name = name
        self.total = max(1, total)
        self.remaining = min(remaining ?? self.total, self.total)
    }
}
