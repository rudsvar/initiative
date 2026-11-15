import SwiftUI

/// One line for armor class, built like `HealthControlRow`: the value with its
/// temporary buffer after it, and the action that changes it. The base value is
/// set in the field above, as max HP is set when tracking starts; the buffer is
/// granted here, with an amount prompt, as temporary HP is.
struct ArmorClassControlRow: View {
    let session: CombatSession
    let combatantId: UUID

    @State private var granting = false
    @State private var amountText = ""

    private var combatant: Combatant? {
        session.combatants.first { $0.id == combatantId }
    }

    var body: some View {
        if let combatant, let ac = combatant.armorClass {
            HStack(spacing: Theme.Spacing.sm) {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xxs) {
                    Text("\(ac)")
                        .fontWeight(combatant.temporaryAC != nil ? .bold : .regular)
                    if let temp = combatant.temporaryAC {
                        Text("+\(temp)")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.statusInfo)
                    }
                }
                .font(Theme.Typography.statLarge)
                .foregroundColor(Theme.textPrimary)

                Spacer(minLength: Theme.Spacing.xs)

                ControlButton(systemImage: "shield.fill", tint: Theme.statusInfo, label: "Grant Temporary AC") {
                    granting = true
                }
            }
            .alert("Grant Temporary AC", isPresented: $granting) {
                TextField("Amount", text: $amountText)
                    .keyboardType(.numberPad)
                Button("Apply") {
                    if let amount = Int(amountText) {
                        session.grantTemporaryAC(to: combatantId, amount: amount)
                    }
                    amountText = ""
                }
                Button("Cancel", role: .cancel) { amountText = "" }
            }
        }
    }
}
