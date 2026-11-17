import SwiftUI

/// Armor class and temporary AC, each on one line in the same layout as the
/// Health card's lines: label, value, change, then − / amount / +; tapping a value
/// sets it exactly. The roster
/// shows the total in play; this card shows the two parts.
struct ArmorClassControlRow: View {
    let session: CombatSession
    let combatantId: UUID

    private var combatant: Combatant? {
        session.combatants.first { $0.id == combatantId }
    }

    var body: some View {
        if let combatant, let ac = combatant.armorClass {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                AmountControlLine(
                    label: "Armor Class", value: ac, change: combatant.recentACChange,
                    decreaseLabel: "Lower armor class", increaseLabel: "Raise armor class",
                    decrease: { amount in session.adjustArmorClass(for: combatantId, by: -amount) },
                    increase: { amount in session.adjustArmorClass(for: combatantId, by: amount) },
                    set: { value in session.setArmorClass(for: combatantId, to: value) }
                )
                AmountControlLine(
                    label: "Temp AC", value: combatant.temporaryAC ?? 0,
                    decreaseLabel: "Lower temporary AC", increaseLabel: "Raise temporary AC",
                    decrease: { amount in session.lowerTemporaryAC(of: combatantId, by: amount) },
                    increase: { amount in session.raiseTemporaryAC(of: combatantId, by: amount) },
                    set: { value in session.setTemporaryAC(for: combatantId, to: value) }
                )
            }
            .foregroundColor(Theme.textPrimary)
        }
    }
}
