import Foundation

/// The effect editor's form: a combatant effect's duration as the three things
/// the editor asks. Reading a duration in and writing it back gives the same
/// duration, so opening an effect and pressing Save never changes how it ends.
struct EffectTiming: Equatable {
    /// How the effect ends.
    enum Ending: Hashable {
        /// After a number of the owner's turns.
        case turns
        /// When a roll at a turn boundary succeeds.
        case save
        /// When the DM removes it (Prone, Grappled, Burning…).
        case removed
    }

    var ending: Ending
    /// Which edge of the owner's turn it counts or rolls on. Unused for `.removed`.
    var boundary: TurnBoundary
    var turns: Int
    /// What to roll, kept as it was: the editor doesn't show it, so a hint set by
    /// whatever created the effect survives a change to the boundary.
    var rollHint: String

    init(ending: Ending, boundary: TurnBoundary = .startOfTurn, turns: Int = 1, rollHint: String = "") {
        self.ending = ending
        self.boundary = boundary
        self.turns = min(20, max(1, turns))
        self.rollHint = rollHint
    }

    /// Nil is a new custom effect, which starts as a save at the start of the turn.
    /// `forRounds` belongs to round effects, which have their own editor.
    init(_ duration: DurationType?) {
        switch duration {
        case .untilStartOfTheirTurn(let turns):
            self.init(ending: .turns, boundary: .startOfTurn, turns: turns)
        case .untilEndOfTheirTurn(let turns):
            self.init(ending: .turns, boundary: .endOfTurn, turns: turns)
        case .untilRollSucceeds(let boundary, let hint):
            self.init(ending: .save, boundary: boundary, rollHint: hint ?? "")
        case .untilRemoved:
            self.init(ending: .removed)
        case .forRounds, .none:
            self.init(ending: .save)
        }
    }

    var durationType: DurationType {
        switch ending {
        case .removed:
            return .untilRemoved
        case .save:
            let hint = rollHint.trimmingCharacters(in: .whitespaces)
            return .untilRollSucceeds(at: boundary, hint: hint.isEmpty ? nil : hint)
        case .turns:
            return boundary == .startOfTurn
                ? .untilStartOfTheirTurn(remainingTurns: turns)
                : .untilEndOfTheirTurn(remainingTurns: turns)
        }
    }
}
