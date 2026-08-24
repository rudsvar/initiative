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
    @State private var acText = ""
    @State private var countText = ""
    @State private var matchedPresetBonus: Int?
    @State private var presets: [CreaturePreset] = []
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                Form {
                    if !presets.isEmpty {
                        Section("Creature") {
                            Menu {
                                ForEach(presets) { preset in
                                    Button(preset.name) { selectPreset(preset) }
                                }
                            } label: {
                                HStack {
                                    Text("Choose Creature")
                                    Spacer()
                                    Text(name.isEmpty ? "None" : name)
                                        .foregroundColor(Theme.textTertiary)
                                }
                            }
                        }
                    }

                    Section("Name") {
                        TextField(text: $name) {
                            Text("Combatant name").foregroundColor(Theme.placeholderText)
                        }
                            .focused($nameFieldFocused)
                            .onChange(of: name) { _, newValue in
                                prefillFromPreset(named: newValue)
                            }
                    }

                    Section("Max HP") {
                        TextField(text: $hpText) {
                            Text("Optional").foregroundColor(Theme.placeholderText)
                        }
                            .keyboardType(.numberPad)
                    }

                    Section("Armor Class") {
                        TextField(text: $acText) {
                            Text("Optional").foregroundColor(Theme.placeholderText)
                        }
                            .keyboardType(.numberPad)
                    }

                    Section("Count") {
                        TextField(text: $countText) {
                            Text("1").foregroundColor(Theme.placeholderText)
                        }
                            .keyboardType(.numberPad)
                    }

                    Section("Initiative") {
                        TextField(text: $initiativeText) {
                            Text("Random 1–20 if left blank").foregroundColor(Theme.placeholderText)
                        }
                            .keyboardType(.numberPad)
                    }

                    if (Int(countText) ?? 1) > 1 {
                        Section {
                            Text(
                                initiativeText.isEmpty
                                    ? "Each copy gets its own random initiative roll."
                                    : "All copies get this same initiative."
                            )
                            .font(.caption)
                            .foregroundColor(Theme.textTertiary)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .listRowBackground(Theme.surfaceRaised)
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
            .onAppear {
                presets = presetStore.listPresets()
                nameFieldFocused = true
            }
        }
    }

    private func selectPreset(_ preset: CreaturePreset) {
        name = preset.name
        hpText = preset.maxHP.map(String.init) ?? ""
        acText = preset.armorClass.map(String.init) ?? ""
        matchedPresetBonus = preset.initiativeBonus
    }

    private func prefillFromPreset(named newName: String) {
        guard let preset = presetStore.preset(named: newName) else {
            matchedPresetBonus = nil
            return
        }
        if hpText.isEmpty, let maxHP = preset.maxHP {
            hpText = String(maxHP)
        }
        if acText.isEmpty, let armorClass = preset.armorClass {
            acText = String(armorClass)
        }
        // Initiative bonus isn't a visible field here (edited only from Main Menu ->
        // Combatants) — it's applied silently to random rolls for a matched preset.
        matchedPresetBonus = preset.initiativeBonus
    }

    private func addCombatant() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let initiative = Int(initiativeText)
        let maxHP = Int(hpText)
        let armorClass = Int(acText)
        let count = max(1, Int(countText) ?? 1)
        let bonus = matchedPresetBonus ?? 0

        if count > 1 {
            session.addCombatants(name: trimmedName, initiative: initiative, maxHP: maxHP, armorClass: armorClass, count: count, initiativeBonus: bonus)
        } else {
            session.addCombatant(name: trimmedName, initiative: initiative, maxHP: maxHP, armorClass: armorClass, initiativeBonus: bonus)
        }
        presetStore.upsert(name: trimmedName, maxHP: maxHP, armorClass: armorClass)

        isPresented = false
    }
}

#Preview {
    AddCombatantSheet(session: CombatSession(), presetStore: PresetStore(), isPresented: .constant(true))
}
