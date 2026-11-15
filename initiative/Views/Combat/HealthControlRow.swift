import SwiftUI

/// One line — current/max readout plus the four actions that change it — used
/// wherever a tracked combatant's health needs to be both shown and edited:
/// the roster row (when it's the current combatant) and the advanced detail
/// screen. Replaces a three-row Current/Max/Temp layout, each with its own
/// persistent Amount field; there's no room for three fields on a roster row,
/// and the amount is different every time anyway, so each button prompts for
/// its own amount inline via an alert instead.
struct HealthControlRow: View {
    let session: CombatSession
    let combatantId: UUID
    /// Smaller buttons for the roster row, full-size on the advanced screen.
    var compact: Bool = false
    /// Surfaces a concentration check raised by damage, so the caller can
    /// present it — this view has no sheet of its own to keep it a plain row.
    var onDamageApplied: (TurnPrompt?) -> Void = { _ in }

    @State private var pendingAction: PendingAction?
    @State private var amountText = ""

    private enum PendingAction: Identifiable {
        case damage, heal, temp, maxIncrease

        var id: Self { self }

        var title: String {
            switch self {
            case .damage: return "Damage"
            case .heal: return "Heal"
            case .temp: return "Grant Temporary HP"
            case .maxIncrease: return "Increase Max HP"
            }
        }
    }

    private var combatant: Combatant? {
        session.combatants.first { $0.id == combatantId }
    }

    var body: some View {
        if let combatant, let current = combatant.currentHP, let max = combatant.maxHP {
            HStack(spacing: Theme.Spacing.sm) {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xxs) {
                    Text("\(current)")
                        .fontWeight(combatant.temporaryHP != nil ? .bold : .regular)
                    Text("/")
                        .foregroundColor(Theme.textTertiary)
                    Text("\(max)")
                        .fontWeight(combatant.maxHPIncreased ? .bold : .regular)
                    if let temp = combatant.temporaryHP {
                        Text("+\(temp)")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.statusInfo)
                    }
                }
                .font(compact ? Theme.Typography.bodyEmphasis : Theme.Typography.statLarge)
                .foregroundColor(combatant.isDead ? Theme.textTertiary : Theme.textPrimary)

                Spacer(minLength: Theme.Spacing.xs)

                actionButton("minus", tint: Theme.statusBad, label: "Damage") { pendingAction = .damage }
                actionButton("plus", tint: Theme.statusGood, label: "Heal") { pendingAction = .heal }
                actionButton("shield.fill", tint: Theme.statusInfo, label: "Grant Temporary HP") { pendingAction = .temp }
                actionButton("arrow.up", tint: Theme.statusInfo, label: "Increase Max HP") { pendingAction = .maxIncrease }
            }
            .alert(
                pendingAction?.title ?? "",
                isPresented: Binding(
                    get: { pendingAction != nil },
                    set: { if !$0 { pendingAction = nil; amountText = "" } }
                )
            ) {
                TextField("Amount", text: $amountText)
                    .keyboardType(.numberPad)
                Button("Apply") { apply() }
                Button("Cancel", role: .cancel) { amountText = "" }
            }
        }
    }

    private func actionButton(
        _ systemImage: String,
        tint: Color,
        label: String,
        action: @escaping () -> Void
    ) -> some View {
        ControlButton(systemImage: systemImage, tint: tint, label: label, compact: compact, action: action)
    }

    private func apply() {
        defer { pendingAction = nil; amountText = "" }
        guard let amount = Int(amountText), amount > 0, let action = pendingAction else { return }
        switch action {
        case .damage:
            onDamageApplied(session.applyDamage(to: combatantId, amount: amount))
        case .heal:
            session.applyHealing(to: combatantId, amount: amount)
        case .temp:
            session.grantTemporaryHP(to: combatantId, amount: amount)
        case .maxIncrease:
            session.increaseMaxHP(for: combatantId, amount: amount)
        }
    }
}
