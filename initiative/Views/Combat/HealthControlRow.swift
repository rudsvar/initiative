import SwiftUI

/// Current HP and max HP, each on one line in the same layout: label, the value, a
/// decrease button, a number box for the amount, and an increase button. Current HP
/// decreases by damage and increases by healing. Healing past max asks first: go above
/// max as temporary HP, or cap at max. Max HP is lowered or raised directly. "Grant temp"
/// sets temporary HP by hand; a new grant never stacks, the larger one stays.
struct HealthControlRow: View {
    let session: CombatSession
    let combatantId: UUID
    /// Surfaces a concentration check raised by damage, so the caller can present it.
    var onDamageApplied: (TurnPrompt?) -> Void = { _ in }

    @State private var currentAmount = "1"
    @State private var maxAmount = "1"
    @State private var grantingTemp = false
    @State private var tempText = ""
    /// The heal waiting on the choice between going above max and capping at max.
    @State private var pendingHeal: Int?

    private var combatant: Combatant? {
        session.combatants.first { $0.id == combatantId }
    }

    var body: some View {
        if let combatant, let current = combatant.currentHP, let max = combatant.maxHP {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                line(
                    "Current HP", "\(current)", change: combatant.recentHPChange,
                    amount: $currentAmount,
                    decrease: { amount in onDamageApplied(session.applyDamage(to: combatantId, amount: amount)) },
                    increase: { amount in
                        let overflow = CombatSession.healOverflow(current: current, max: max, amount: amount)
                        if overflow > 0 {
                            pendingHeal = amount
                        } else {
                            session.heal(combatantId, amount: amount, goAboveMax: false)
                        }
                    },
                    decreaseLabel: "Damage",
                    increaseLabel: "Heal"
                )
                tempLine(combatant)
                line(
                    "Max HP", "\(max)", change: combatant.recentMaxHPChange,
                    amount: $maxAmount,
                    decrease: { amount in session.decreaseMaxHP(for: combatantId, amount: amount) },
                    increase: { amount in session.increaseMaxHP(for: combatantId, amount: amount) },
                    decreaseLabel: "Lower max",
                    increaseLabel: "Raise max"
                )
            }
            .foregroundColor(combatant.isDead ? Theme.textTertiary : Theme.textPrimary)
            .confirmationDialog(
                "Heal past max?",
                isPresented: Binding(get: { pendingHeal != nil }, set: { if !$0 { pendingHeal = nil } }),
                titleVisibility: .visible
            ) {
                Button("Go above max as temporary HP") {
                    if let amount = pendingHeal { session.heal(combatantId, amount: amount, goAboveMax: true) }
                    pendingHeal = nil
                }
                Button("Cap at max") {
                    if let amount = pendingHeal { session.heal(combatantId, amount: amount, goAboveMax: false) }
                    pendingHeal = nil
                }
                Button("Cancel", role: .cancel) { pendingHeal = nil }
            } message: {
                if let amount = pendingHeal {
                    Text("Healing \(amount) takes \(current) past the maximum of \(max).")
                }
            }
            .alert("Grant Temporary HP", isPresented: $grantingTemp) {
                TextField("Amount", text: $tempText)
                    .keyboardType(.numberPad)
                Button("Apply") {
                    if let amount = Int(tempText) {
                        session.grantTemporaryHP(to: combatantId, amount: amount)
                    }
                    tempText = ""
                }
                Button("Cancel", role: .cancel) { tempText = "" }
            }
        }
    }

    /// Label, value, change, then the decrease button, the number box and the increase button.
    private func line(
        _ label: String,
        _ value: String,
        change: Int?,
        amount: Binding<String>,
        decrease: @escaping (Int) -> Void,
        increase: @escaping (Int) -> Void,
        decreaseLabel: String,
        increaseLabel: String
    ) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.textTertiary)
                .frame(width: 84, alignment: .leading)
            Text(value)
                .font(Theme.Typography.statLarge)
            if let change {
                ChangeLabel(change: change)
                    .font(Theme.Typography.bodyEmphasis)
            }
            Spacer(minLength: Theme.Spacing.xs)
            ControlButton(systemImage: "minus", tint: Theme.statusBad, label: decreaseLabel) {
                decrease(Self.amount(from: amount.wrappedValue))
            }
            TextField("1", text: amount)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(Theme.Typography.bodyEmphasis)
                .foregroundColor(Theme.textPrimary)
                .frame(width: 48, height: 38)
                .background(Theme.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            ControlButton(systemImage: "plus", tint: Theme.statusGood, label: increaseLabel) {
                increase(Self.amount(from: amount.wrappedValue))
            }
        }
    }

    /// "Grant temp": the temporary HP is only ever set by healing past max, or by hand.
    private func tempLine(_ combatant: Combatant) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Text("Temp HP")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.textTertiary)
                .frame(width: 84, alignment: .leading)
            Text(combatant.temporaryHP.map { "\($0)" } ?? "none")
                .font(Theme.Typography.statLarge)
                .foregroundColor(combatant.temporaryHP == nil ? Theme.textTertiary : Theme.statusInfo)
            Spacer(minLength: 0)
            Button("Grant temp") { grantingTemp = true }
                .font(Theme.Typography.bodyEmphasis)
                .foregroundColor(Theme.statusInfo)
                .buttonStyle(.plain)
        }
    }

    /// The number in the box, at least 1.
    private static func amount(from text: String) -> Int {
        max(1, Int(text) ?? 1)
    }
}
