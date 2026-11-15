import SwiftUI

/// Current and max HP, and how they are changed. Tap the current value to take
/// damage or heal; tap the max to lower or raise it. Each opens `AdjustAmountSheet`,
/// where the amount is chosen with − and +. Beside the numbers, the net change since
/// the combatant's turn started shows in red (down) or green (up). The shield grants
/// temporary HP, which replaces any earlier grant.
struct HealthControlRow: View {
    let session: CombatSession
    let combatantId: UUID
    /// Smaller controls for the roster, full size on the advanced screen.
    var compact: Bool = false
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
            HStack(spacing: Theme.Spacing.sm) {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xs) {
                    tapValue("\(current)") { sheet = .current }
                    Text("/")
                        .foregroundColor(Theme.textTertiary)
                    tapValue("\(max)") { sheet = .max }
                    if let change = combatant.recentHPChange {
                        Text(Format.signed(change))
                            .font(Theme.Typography.bodyEmphasis)
                            .foregroundColor(change < 0 ? Theme.statusBad : Theme.statusGood)
                    }
                    if let temp = combatant.temporaryHP {
                        Label("\(temp)", systemImage: "shield.fill")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.statusInfo)
                    }
                }
                .font(compact ? Theme.Typography.bodyEmphasis : Theme.Typography.statLarge)
                .foregroundColor(combatant.isDead ? Theme.textTertiary : Theme.textPrimary)

                Spacer(minLength: Theme.Spacing.xs)

                ControlButton(systemImage: "shield.fill", tint: Theme.statusInfo, label: "Grant Temporary HP", compact: compact) {
                    grantingTemp = true
                }
            }
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

    /// A number you tap to open its sheet. Boxed so it reads as a control.
    private func tapValue(_ text: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xxs)
                .background(Theme.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
