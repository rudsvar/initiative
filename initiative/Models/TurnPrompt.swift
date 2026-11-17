import Foundation

/// The result of a roll the DM reports. A death save can be a natural 20 or a natural 1;
/// every other prompt is a plain success or failure.
enum RollOutcome: Equatable, Hashable {
    case criticalFailure, failure, success, criticalSuccess

    var succeeded: Bool { self == .success || self == .criticalSuccess }

    init(succeeded: Bool) { self = succeeded ? .success : .failure }
}

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
        /// ends it, because the roll is to *keep* the thing rather than to
        /// shake it off. No id — concentration is a bare flag on the combatant,
        /// not an `Effect`, so `combatantID` alone says what it's about.
        case concentration
        /// A roll owed by something anchored to the round rather than to any
        /// combatant. Resolves like `effect`: succeeding removes it.
        case roundEffect(id: UUID)
        /// Damage that comes due at the start of the combatant's turn (Burning). The
        /// DM rolls it and types the number; the app only asks and applies it.
        case damage(effectID: UUID)
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

    /// Labels for the two answers — always the same two words regardless of
    /// subject. Per-subject phrasing ("Made it"/"Not yet", "Held it"/"Lost
    /// it") was tried first, but every prompt already states what's being
    /// rolled for in its own `title`, so restating the outcome in different
    /// words each time added variety without adding information.
    var successLabel: String { "Success" }
    var failureLabel: String { "Failure" }
}
