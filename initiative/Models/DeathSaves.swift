import Foundation

/// A downed combatant's running tally of death saves.
///
/// The tally lives on the Dying effect (`Effect.deathSaves`), so a dying combatant
/// shows as an effect like any other: a chip, and a roll at the start of its turn.
/// Both outcomes count here, which is why the tally is not a `DurationType`: you
/// can fail twice and be healed, or succeed three times and stabilise.
///
/// The app never rolls and never decides — the DM reports each roll's outcome
/// with one tap. Three of either ends it.
struct DeathSaves: Codable, Hashable {
    static let required = 3

    var successes: Int = 0
    var failures: Int = 0

    var isStable: Bool { successes >= Self.required }
    var isDead: Bool { failures >= Self.required }
    /// Once resolved, the tally is kept rather than cleared: "stable at 0 HP" is a
    /// real state that has to be distinguishable from "dead at 0 HP", and from
    /// "never started dying".
    var isResolved: Bool { isStable || isDead }

    /// A natural 1 counts as two failures.
    mutating func recordCriticalFailure() {
        guard !isResolved else { return }
        failures += 2
    }

    mutating func record(success: Bool) {
        guard !isResolved else { return }
        if success {
            successes += 1
        } else {
            failures += 1
        }
    }
}
