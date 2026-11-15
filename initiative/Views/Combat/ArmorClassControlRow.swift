import SwiftUI

/// Armor class, changed the same way as current HP: tap the value, choose the
/// amount with − and +, then lower or raise. The change since the combatant's turn
/// started shows beside it, in red or green. The shield grants a temporary buffer,
/// which replaces any earlier grant.
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
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xs) {
                    Button { adjusting = true } label: {
                        Text("\(ac)")
                            .padding(.horizontal, Theme.Spacing.sm)
                            .padding(.vertical, Theme.Spacing.xxs)
                            .background(Theme.surfaceRaised)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    if let change = combatant.recentACChange {
                        Text(Format.signed(change))
                            .font(Theme.Typography.bodyEmphasis)
                            .foregroundColor(change < 0 ? Theme.statusBad : Theme.statusGood)
                    }
                    if let temp = combatant.temporaryAC {
                        Label("\(temp)", systemImage: "shield.fill")
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
