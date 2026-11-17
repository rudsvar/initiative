import Foundation

/// "Is Alpha concentrating on Frightened?" — asked after a condition is put on
/// someone else during Alpha's turn. See `CombatSession.concentrationSuggestion`.
struct ConcentrationSuggestion: Identifiable, Equatable {
    var id: UUID { casterID }
    let casterID: UUID
    let casterName: String
    let effectName: String

    var question: String { "Is \(casterName) concentrating on \(effectName)?" }
}
