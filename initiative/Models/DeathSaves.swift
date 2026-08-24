import Foundation

/// A downed combatant's running tally of death saves.
///
/// This is the one piece of temporary state that deliberately **isn't** an
/// `Effect`. Everything else that ticks resolves one way — it expires, or it
/// doesn't yet — but here both outcomes count for something: you can fail twice
/// and be healed, or succeed three times and stabilise. Expressing that through
/// `DurationType` would mean a case carrying two tallies and a
/// death-on-failure rule that exactly one thing uses. What *is* shared is the
/// turn prompt, which is the part worth sharing.
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

    mutating func record(success: Bool) {
        guard !isResolved else { return }
        if success {
            successes += 1
        } else {
            failures += 1
        }
    }
}
