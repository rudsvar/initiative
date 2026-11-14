import Foundation

/// A quick-pick for the *other* kind of effect: something a combatant can't do
/// yet, rather than something wrong with them.
///
/// Used to offer several DC/roll-specific variants (Recharge 5–6, Recharge 6…)
/// and a separate "Once per encounter" pick — both dropped for being too
/// specific to one ruleset's numbers. What's left is the shape every recharge
/// ability actually shares: something gets rolled on the DM's own turn, and a
/// pass clears it. The DM tracks what to roll for in their own head; the app
/// only needs to remember that a roll is owed. "Once per encounter" is now
/// `LimitedUse` (with total 1), which is also how a DM would want to track a
/// three-per-day or Legendary Action resource — no reason to special-case the
/// one-use version.
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
            label: "Recharge",
            effectName: "Recharging",
            durationType: .untilRollSucceeds(at: .startOfTurn, hint: nil)
        ),
    ]
}
