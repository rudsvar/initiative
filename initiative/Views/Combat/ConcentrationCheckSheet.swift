import SwiftUI

extension View {
    /// Asks a concentration check raised by damage and resolves it at once. Damage
    /// isn't a turn boundary, so these are answered on their own rather than
    /// handed to `nextTurn`. Used by the roster and the combatant screen.
    func concentrationCheckSheet(_ check: Binding<TurnPrompt?>, session: CombatSession) -> some View {
        sheet(item: check) { prompt in
            TurnPromptView(prompts: [prompt]) { answers, _ in
                for (prompt, outcome) in answers {
                    session.resolvePrompt(prompt, outcome: outcome)
                }
                check.wrappedValue = nil
            }
        }
    }
}
