import SwiftUI

/// Armor class on one line: the tappable value (Lower/Raise), its change since the
/// turn started, and "temp" text that grants a temporary buffer.
struct ArmorClassControlRow: View {
    let session: CombatSession
    let combatantId: UUID

    @State private var adjusting = false
    @State private var granting = false
    @State private var amountText = ""

    private var combatant: Combatant? {
        session.combatants.first { $0.id == combatantId }
    }

    var body: some View {
        if let combatant, let ac = combatant.armorClass {
            HStack(spacing: Theme.Spacing.sm) {
                Text("Armor Class")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.textTertiary)
                    .frame(width: 84, alignment: .leading)
                Button { adjusting = true } label: {
                    Text("\(ac)")
                        .font(Theme.Typography.statLarge)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xxs)
                        .background(Theme.surfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                }
                .buttonStyle(.plain)
                if let change = combatant.recentACChange {
                    ChangeLabel(change: change)
                        .font(Theme.Typography.bodyEmphasis)
                }
                Spacer(minLength: Theme.Spacing.sm)
                Button { granting = true } label: {
                    Text(combatant.temporaryAC.map { "temp \($0)" } ?? "temp —")
                        .font(Theme.Typography.bodyEmphasis)
                        .foregroundColor(combatant.temporaryAC == nil ? Theme.textTertiary : Theme.statusInfo)
                }
                .buttonStyle(.plain)
            }
            .foregroundColor(Theme.textPrimary)
            .sheet(isPresented: $adjusting) {
                AdjustAmountSheet(
                    title: "Armor Class",
                    decreaseLabel: "Lower",
                    increaseLabel: "Raise",
                    onDecrease: { amount in session.adjustArmorClass(for: combatantId, by: -amount) },
                    onIncrease: { amount in session.adjustArmorClass(for: combatantId, by: amount) }
                )
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
