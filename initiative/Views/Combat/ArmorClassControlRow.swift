import SwiftUI

/// Armor class, on one line with its action: tap the value to lower or raise it
/// (`AdjustAmountSheet`). The change since the turn started shows beside it, red or
/// green. "Grant temp" sets a temporary buffer, which replaces any earlier grant.
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
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
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
                    Spacer(minLength: 0)
                }
                HStack(spacing: Theme.Spacing.sm) {
                    Text("Temp AC")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.textTertiary)
                        .frame(width: 84, alignment: .leading)
                    Text(combatant.temporaryAC.map { "\($0)" } ?? "none")
                        .font(Theme.Typography.statLarge)
                        .foregroundColor(combatant.temporaryAC == nil ? Theme.textTertiary : Theme.statusInfo)
                    Spacer(minLength: 0)
                    Button("Grant temp") { granting = true }
                        .font(Theme.Typography.bodyEmphasis)
                        .foregroundColor(Theme.statusInfo)
                        .buttonStyle(.plain)
                }
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
