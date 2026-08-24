import Foundation

/// Quick-picks for the *other* kind of effect: something a combatant can't do
/// yet, rather than something wrong with them.
///
/// These exist so the common cases are one tap. Configuring "roll at the start
/// of my turn, and here's what to roll" from scratch every time a dragon
/// breathes is exactly how a screen ends up cluttered — the library is what lets
/// the extra capability stay out of the way until it's wanted.
struct StandardCooldown: Identifiable {
    var id: String { label }
    /// What the DM picks from the list.
    let label: String
    /// Default name for the effect itself, which they'll usually overwrite with
    /// the ability's real name.
    let effectName: String
    let durationType: DurationType

    static let all: [StandardCooldown] = [
        StandardCooldown(
            label: "Recharge 5–6",
            effectName: "Recharging",
            durationType: .untilRollSucceeds(at: .startOfTurn, hint: "5–6 on a d6")
        ),
        StandardCooldown(
            label: "Recharge 6",
            effectName: "Recharging",
            durationType: .untilRollSucceeds(at: .startOfTurn, hint: "6 on a d6")
        ),
        StandardCooldown(
            label: "Recharge 4–6",
            effectName: "Recharging",
            durationType: .untilRollSucceeds(at: .startOfTurn, hint: "4–6 on a d6")
        ),
        StandardCooldown(
            label: "Once per encounter",
            effectName: "Used",
            // No roll and no countdown: it's gone for the fight, and the DM
            // removes it when the fight ends.
            durationType: .untilEndOfTheirTurn(remainingTurns: 99)
        ),
    ]
}
