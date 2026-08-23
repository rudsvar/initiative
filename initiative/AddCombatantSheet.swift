import SwiftUI

/// Full-screen modal for adding one or more combatants. Replaced an earlier inline
/// row design that was too easy to trigger by accident and too fiddly to hit the
/// small per-field controls — a native Form gives each field a full-size tap target.
struct AddCombatantSheet: View {
    let session: CombatSession
    let presetStore: PresetStore
    @Binding var isPresented: Bool

    @State private var name = ""
    @State private var initiativeText = ""
    @State private var hpText = ""
    @State private var countText = ""
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Combatant name", text: $name)
                        .focused($nameFieldFocused)
                        .onChange(of: name) { _, newValue in
                            prefillFromPreset(named: newValue)
                        }
                }

                Section("Initiative") {
                    TextField("Random 1–20 if left blank", text: $initiativeText)
                        .keyboardType(.numberPad)
                }

                Section("Max HP") {
                    TextField("Optional", text: $hpText)
                        .keyboardType(.numberPad)
                }

                Section("Count") {
                    TextField("1", text: $countText)
                        .keyboardType(.numberPad)
                }

                if (Int(countText) ?? 1) > 1 {
                    Section {
                        Text("Each copy gets its own random initiative roll.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Add Combatant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addCombatant() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { nameFieldFocused = true }
        }
    }

    private func prefillFromPreset(named newName: String) {
        guard hpText.isEmpty, let preset = presetStore.preset(named: newName), let maxHP = preset.maxHP else { return }
        hpText = String(maxHP)
    }

    private func addCombatant() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let initiative = Int(initiativeText)
        let maxHP = Int(hpText)
        let count = max(1, Int(countText) ?? 1)

        if count > 1 {
            session.addCombatants(name: trimmedName, initiative: initiative, maxHP: maxHP, count: count)
        } else {
            session.addCombatant(name: trimmedName, initiative: initiative ?? Int.random(in: 1...20), maxHP: maxHP)
        }
        presetStore.upsert(name: trimmedName, maxHP: maxHP)

        isPresented = false
    }
}

#Preview {
    AddCombatantSheet(session: CombatSession(), presetStore: PresetStore(), isPresented: .constant(true))
}
