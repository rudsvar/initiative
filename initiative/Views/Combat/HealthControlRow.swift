import SwiftUI

/// Current HP and max HP, two lines. Current HP carries its change and its temporary
/// HP, and its number opens Damage/Heal. The max number opens Lower/Raise max. The
/// "temp" text opens the grant prompt, which replaces any earlier grant.
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
                HStack(spacing: Theme.Spacing.sm) {
                    line("Current HP", "\(current)", change: combatant.recentHPChange) { sheet = .current }
                    Spacer(minLength: Theme.Spacing.sm)
                    tempButton(combatant.temporaryHP)
                }
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

    /// A label, the tappable number, and its change since the turn started.
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
        }
    }

    /// "temp 5", or "temp —" when there is none. Tapping either grants temporary HP.
    private func tempButton(_ temp: Int?) -> some View {
        Button { grantingTemp = true } label: {
            Text(temp.map { "temp \($0)" } ?? "temp —")
                .font(Theme.Typography.bodyEmphasis)
                .foregroundColor(temp == nil ? Theme.textTertiary : Theme.statusInfo)
        }
        .buttonStyle(.plain)
    }
}
