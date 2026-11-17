import SwiftUI

/// Full-screen modal for adding one or more combatants. Replaced an earlier inline
/// row design that was too easy to trigger by accident and too fiddly to hit the
/// small per-field controls — a native Form gives each field a full-size tap target.
/// The creature fields are `CombatantDraftFields`, shared with an encounter's Add
/// Creature; initiative is this sheet's own.
struct AddCombatantSheet: View {
    let session: CombatSession
    let presetStore: PresetStore
    @Binding var isPresented: Bool

    @State private var draft = CombatantDraft()
    @State private var initiativeText = ""

    var body: some View {
        NavigationStack {
            Form {
                CombatantDraftFields(draft: $draft, presetStore: presetStore, offersCharacters: true)

                Section("Initiative") {
                    TextField(text: $initiativeText) {
                        Text("Random 1–20 if left blank").foregroundColor(Theme.placeholderText)
                    }
                    .keyboardType(.numberPad)
                }
                .listRowBackground(Theme.surfaceRaised)

                if draft.count > 1 {
                    Section {
                        Text(
                            initiativeText.isEmpty
                                ? "Each copy gets its own random initiative roll."
                                : "All copies get this same initiative."
                        )
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.textTertiary)
                    }
                    .listRowBackground(Theme.surfaceRaised)
                }
            }
            // Row background goes on each Section, never on the Form:
            // attached to the Form it is silently ignored.
            .scrollContentBackground(.hidden)
            .themedScreen()
            .navigationTitle("Add Combatant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addCombatant() }
                        .fontWeight(.semibold)
                        .disabled(!draft.isValid)
                }
            }
        }
    }

    private func addCombatant() {
        guard draft.isValid else { return }
        session.addCombatants(
            name: draft.trimmedName,
            initiative: Int(initiativeText),
            maxHP: draft.maxHP,
            armorClass: draft.armorClass,
            count: draft.count,
            initiativeBonus: draft.initiativeBonus ?? 0,
            isPlayer: draft.isPlayer
        )
        presetStore.upsert(name: draft.trimmedName, maxHP: draft.maxHP, armorClass: draft.armorClass, isPlayer: draft.isPlayer)
        isPresented = false
    }
}

#Preview {
    AddCombatantSheet(session: CombatSession(), presetStore: PresetStore(), isPresented: .constant(true))
}
