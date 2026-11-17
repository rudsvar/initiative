import SwiftUI

/// Current HP and max HP, each on one line in the same layout: label, the value, a
/// decrease button, a number box for the amount, and an increase button. Current HP
/// decreases by damage and increases by healing. Healing past max asks first: go above
/// max as temporary HP, or cap at max. Max HP is lowered or raised directly. "Grant temp"
/// adds temporary HP; a new grant never stacks, the larger one stays. Tapping any of the
/// three values sets it directly, as a correction.
struct HealthControlRow: View {
    let session: CombatSession
    let combatantId: UUID
    /// Surfaces a concentration check raised by damage, so the caller can present it.
    var onDamageApplied: (TurnPrompt?) -> Void = { _ in }

    @State private var currentAmount = "1"
    @State private var maxAmount = "1"
    @State private var grantingTemp = false
    @State private var tempText = ""
    /// Which value is being typed over, and what has been typed so far.
    private enum Field: String { case current = "Current HP", max = "Max HP", temp = "Temporary HP" }
    @State private var editing: Field?
    @State private var editText = ""

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
                    onTapValue: { beginEditing(.current, value: current) },
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
                    onTapValue: { beginEditing(.max, value: max) },
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
            .alert(
                "Set \(editing?.rawValue ?? "")",
                isPresented: Binding(get: { editing != nil }, set: { if !$0 { editing = nil } })
            ) {
                TextField("Value", text: $editText)
                    .keyboardType(.numberPad)
                Button("Set") {
                    if let value = Int(editText), let field = editing {
                        switch field {
                        case .current: session.setCurrentHP(for: combatantId, to: value)
                        case .max: session.setMaxHP(for: combatantId, to: value)
                        case .temp: session.setTemporaryHP(for: combatantId, to: value)
                        }
                    }
                    editing = nil
                }
                Button("Cancel", role: .cancel) { editing = nil }
            } message: {
                Text(editing == .temp ? "0 clears it." : "Corrects the value directly, with no damage or healing rules applied.")
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

    private func line(
        _ label: String,
        _ value: String,
        change: Int?,
        onTapValue: @escaping () -> Void,
        amount: Binding<String>,
        decrease: @escaping (Int) -> Void,
        increase: @escaping (Int) -> Void,
        decreaseLabel: String,
        increaseLabel: String
    ) -> some View {
        ValueAmountLine(
            label: label, value: value, change: change, onTapValue: onTapValue,
            amount: amount, decrease: decrease, increase: increase,
            decreaseLabel: decreaseLabel, increaseLabel: increaseLabel
        )
    }

    private func tempLine(_ combatant: Combatant) -> some View {
        TempValueLine(
            label: "Temp HP",
            value: combatant.temporaryHP.map { "\($0)" },
            buttonTitle: "Grant temp",
            onTapValue: { beginEditing(.temp, value: combatant.temporaryHP ?? 0) },
            onButton: { grantingTemp = true }
        )
    }

    private func beginEditing(_ field: Field, value: Int) {
        editText = "\(value)"
        editing = field
    }

    /// The number in the box, at least 1.
    private static func amount(from text: String) -> Int {
        max(1, Int(text) ?? 1)
    }
}

/// One row of the health layout: label, the tappable value, its change, then the
/// decrease button, a number box and the increase button. Armor class uses it too, so
/// the two read the same.
struct ValueAmountLine: View {
    let label: String
    let value: String
    let change: Int?
    let onTapValue: () -> Void
    @Binding var amount: String
    let decrease: (Int) -> Void
    let increase: (Int) -> Void
    let decreaseLabel: String
    let increaseLabel: String

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.textTertiary)
                .frame(width: 84, alignment: .leading)
            Button(action: onTapValue) {
                Text(value)
                    .font(Theme.Typography.statLarge)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(label) \(value), tap to set")
            if let change {
                ChangeLabel(change: change)
                    .font(Theme.Typography.bodyEmphasis)
            }
            Spacer(minLength: Theme.Spacing.xs)
            ControlButton(systemImage: "minus", tint: Theme.statusBad, label: decreaseLabel) {
                decrease(Self.amount(from: amount))
            }
            TextField("1", text: $amount)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(Theme.Typography.bodyEmphasis)
                .foregroundColor(Theme.textPrimary)
                .frame(width: 48, height: 38)
                .background(Theme.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            ControlButton(systemImage: "plus", tint: Theme.statusGood, label: increaseLabel) {
                increase(Self.amount(from: amount))
            }
        }
    }

    /// The number in the box, at least 1.
    static func amount(from text: String) -> Int {
        max(1, Int(text) ?? 1)
    }
}

/// The temporary row under a value: the tappable value ("none" when unset) and a grant button.
struct TempValueLine: View {
    let label: String
    let value: String?
    let buttonTitle: String
    let onTapValue: () -> Void
    let onButton: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.textTertiary)
                .frame(width: 84, alignment: .leading)
            Button(action: onTapValue) {
                Text(value ?? "none")
                    .font(Theme.Typography.statLarge)
                    .foregroundColor(value == nil ? Theme.textTertiary : Theme.statusInfo)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(label) \(value ?? "none"), tap to set")
            Spacer(minLength: 0)
            Button(buttonTitle, action: onButton)
                .font(Theme.Typography.bodyEmphasis)
                .foregroundColor(Theme.statusInfo)
                .buttonStyle(.plain)
        }
    }
}
