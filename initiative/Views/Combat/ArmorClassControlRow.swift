import SwiftUI

/// Armor class laid out like the health rows: the tappable value (tap to type it
/// directly), its change since the turn started, and Lower/Raise buttons with an amount
/// box. Temp AC sits underneath like temp HP, with a Grant button.
struct ArmorClassControlRow: View {
    let session: CombatSession
    let combatantId: UUID

    @State private var amount = "1"
    @State private var granting = false
    @State private var grantText = ""
    @State private var setting = false
    @State private var settingTemp = false
    @State private var setText = ""

    private var combatant: Combatant? {
        session.combatants.first { $0.id == combatantId }
    }

    var body: some View {
        if let combatant, let ac = combatant.armorClass {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                ValueAmountLine(
                    label: "Armor Class", value: "\(ac)", change: combatant.recentACChange,
                    onTapValue: { setText = "\(ac)"; setting = true },
                    amount: $amount,
                    decrease: { session.adjustArmorClass(for: combatantId, by: -$0) },
                    increase: { session.adjustArmorClass(for: combatantId, by: $0) },
                    decreaseLabel: "Lower",
                    increaseLabel: "Raise"
                )
                TempValueLine(
                    label: "Temp AC",
                    value: combatant.temporaryAC.map { "\($0)" },
                    buttonTitle: "Grant temp",
                    onTapValue: { setText = "\(combatant.temporaryAC ?? 0)"; settingTemp = true },
                    onButton: { granting = true }
                )
            }
            .foregroundColor(Theme.textPrimary)
            .alert("Set Armor Class", isPresented: $setting) {
                TextField("Value", text: $setText)
                    .keyboardType(.numberPad)
                Button("Set") {
                    if let value = Int(setText) { session.setArmorClass(for: combatantId, to: value) }
                    setText = ""
                }
                Button("Cancel", role: .cancel) { setText = "" }
            } message: {
                Text("Corrects the value directly.")
            }
            .alert("Set Temporary AC", isPresented: $settingTemp) {
                TextField("Value", text: $setText)
                    .keyboardType(.numberPad)
                Button("Set") {
                    if let value = Int(setText) { session.setTemporaryAC(for: combatantId, to: value) }
                    setText = ""
                }
                Button("Cancel", role: .cancel) { setText = "" }
            } message: {
                Text("0 clears it.")
            }
            .alert("Grant Temporary AC", isPresented: $granting) {
                TextField("Amount", text: $grantText)
                    .keyboardType(.numberPad)
                Button("Apply") {
                    if let amount = Int(grantText) {
                        session.grantTemporaryAC(to: combatantId, amount: amount)
                    }
                    grantText = ""
                }
                if combatant.temporaryAC != nil {
                    Button("Remove temporary AC", role: .destructive) {
                        session.removeTemporaryAC(from: combatantId)
                        grantText = ""
                    }
                }
                Button("Cancel", role: .cancel) { grantText = "" }
            } message: {
                Text("Added to armor class for this fight. A new grant replaces the old one.")
            }
        }
    }
}
