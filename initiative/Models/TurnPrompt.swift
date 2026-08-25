import Foundation

/// One thing the DM has to answer before the turn can move on.
///
/// The app's job here is to *remember that a roll is owed* — the part that
/// actually gets forgotten mid-combat — not to roll it or judge it. Every prompt
/// is answered with one tap, and the two answers always mean the same shape of
/// thing: it went the good way, or it didn't.
struct TurnPrompt: Identifiable, Hashable {
    enum Subject: Hashable {
        /// A `.untilRollSucceeds` effect: succeeding removes it.
        case effect(id: UUID)
        /// A death save: both outcomes count toward their own total.
        case deathSave
        /// A concentration check. **Inverted** from `effect`: failing is what
        /// removes it, because the roll is to *keep* the thing rather than to
        /// shake it off.
        case concentration(id: UUID)
        /// A roll owed by something anchored to the round rather than to any
        /// combatant. Resolves like `effect`: succeeding removes it.
        case roundEffect(id: UUID)
    }

    let id: UUID
    /// The owning combatant, or nil for a round-anchored prompt — the round
    /// belongs to no one, which is the whole point of it.
    let combatantID: UUID?
    /// Who the prompt is about. "The round" when it isn't about anyone.
    let combatantName: String
    let subject: Subject
    /// What's being rolled for, phrased for the DM — "Roll to recharge Breath
    /// Weapon", "Roll a save vs Frightened", "Death save".
    let title: String
    /// What to roll, when the DM wrote it down — free text, never evaluated.
    let hint: String?
    /// Running tally, for death saves only.
    let deathSaves: DeathSaves?

    /// Labels for the two answers. Death saves count both outcomes, so "Not yet"
    /// would be a lie — a failed death save is not nothing happening.
    var successLabel: String {
        switch subject {
        case .deathSave: return "Success"
        case .concentration: return "Held it"
        case .effect, .roundEffect: return "Made it"
        }
    }

    /// "Not yet" would be a lie for the two subjects where failing means
    /// something happened rather than nothing.
    var failureLabel: String {
        switch subject {
        case .deathSave: return "Failure"
        case .concentration: return "Lost it"
        case .effect, .roundEffect: return "Not yet"
        }
    }
}
