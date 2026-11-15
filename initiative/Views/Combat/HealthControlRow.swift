import SwiftUI

/// Current HP and max HP, each on its own line with its own action. Tap the current
/// value to take damage or heal; tap the max value to lower or raise it. Each opens
/// `AdjustAmountSheet`. The change since the turn started shows beside current HP,
/// red or green. "Grant temp" sets temporary HP, which replaces any earlier grant.
struct HealthControlRow: View {
    let session: CombatSession
    let combatantId: UUID
    /// Surfaces a concentration check raised by damage, so the caller can present it.
    var onDamageApplied: (TurnPrompt?) -> Void = { _ in }

    @State private var sheet: Sheet?
    @State private var grantingTemp = false
    @State private var tempText = ""

    private enum Sheet: Identifiable {
        case current, max
        var id: Self { self }
    }

    private var combatant: Combatant? {
        session.combatants.first { $0.id == combatantId }
    }

    var body: some View {
        if let combatant, let current = combatant.currentHP, let max = combatant.maxHP {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                line("Current HP", "\(current)", change: combatant.recentHPChange) { sheet = .current }
                tempLine(combatant)
                line("Max HP", "\(max)", change: combatant.recentMaxHPChange) { sheet = .max }
            }
            .foregroundColor(combatant.isDead ? Theme.textTertiary : Theme.textPrimary)
            .sheet(item: $sheet) { which in
                switch which {
                case .current:
                    AdjustAmountSheet(
                        title: "Hit Points",
                        decreaseLabel: "Damage",
                        increaseLabel: "Heal",
                        onDecrease: { amount in onDamageApplied(session.applyDamage(to: combatantId, amount: amount)) },
                        onIncrease: { amount in session.applyHealing(to: combatantId, amount: amount) }
                    )
                case .max:
                    AdjustAmountSheet(
                        title: "Max Hit Points",
                        decreaseLabel: "Lower max",
                        increaseLabel: "Raise max",
                        onDecrease: { amount in session.decreaseMaxHP(for: combatantId, amount: amount) },
                        onIncrease: { amount in session.increaseMaxHP(for: combatantId, amount: amount) }
                    )
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

    /// A label, the tappable value, and the change since the turn started.
    private func line(_ label: String, _ value: String, change: Int?, action: @escaping () -> Void) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.textTertiary)
                .frame(width: 84, alignment: .leading)
            Button(action: action) {
                Text(value)
                    .font(Theme.Typography.statLarge)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xxs)
                    .background(Theme.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            }
            .buttonStyle(.plain)
            if let change {
                ChangeLabel(change: change)
                    .font(Theme.Typography.bodyEmphasis)
            }
            Spacer(minLength: 0)
        }
    }

    /// The temporary HP line, with its own action beside it.
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
}
