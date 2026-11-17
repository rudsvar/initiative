import SwiftUI

/// Current HP, temporary HP and max HP, each on one line in the same layout: label,
/// the value, a decrease button, a number box for the amount, and an increase
/// button. Current HP decreases by damage and increases by healing. Healing past max
/// asks first: go above max as temporary HP, or cap at max. Temporary HP and max HP
/// are lowered or raised directly. Tapping any of the three values sets it exactly,
/// as a correction.
struct HealthControlRow: View {
    let session: CombatSession
    let combatantId: UUID
    /// Surfaces a concentration check raised by damage, so the caller can present it.
    var onDamageApplied: (TurnPrompt?) -> Void = { _ in }

    /// The heal waiting on the choice between going above max and capping at max.
    @State private var pendingHeal: Int?

    private var combatant: Combatant? {
        session.combatants.first { $0.id == combatantId }
    }

    var body: some View {
        if let combatant, let current = combatant.currentHP, let max = combatant.maxHP {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                AmountControlLine(
                    label: "Current HP", value: current, change: combatant.recentHPChange,
                    decreaseLabel: "Damage", increaseLabel: "Heal",
                    decrease: { amount in onDamageApplied(session.applyDamage(to: combatantId, amount: amount)) },
                    increase: { amount in
                        let overflow = CombatSession.healOverflow(current: current, max: max, amount: amount)
                        if overflow > 0 {
                            pendingHeal = amount
                        } else {
                            session.heal(combatantId, amount: amount, goAboveMax: false)
                        }
                    },
                    set: { value in session.setCurrentHP(for: combatantId, to: value) }
                )
                AmountControlLine(
                    label: "Temp HP", value: combatant.temporaryHP ?? 0,
                    decreaseLabel: "Lower temporary HP", increaseLabel: "Raise temporary HP",
                    decrease: { amount in session.lowerTemporaryHP(of: combatantId, by: amount) },
                    increase: { amount in session.raiseTemporaryHP(of: combatantId, by: amount) },
                    set: { value in session.setTemporaryHP(for: combatantId, to: value) }
                )
                AmountControlLine(
                    label: "Max HP", value: max, change: combatant.recentMaxHPChange,
                    decreaseLabel: "Lower max", increaseLabel: "Raise max",
                    decrease: { amount in session.decreaseMaxHP(for: combatantId, amount: amount) },
                    increase: { amount in session.increaseMaxHP(for: combatantId, amount: amount) },
                    set: { value in session.setMaxHP(for: combatantId, to: value) }
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
        }
    }
}
