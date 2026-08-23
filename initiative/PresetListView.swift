import SwiftUI

/// Browse/edit/delete creature presets. Presets accumulate automatically as
/// combatants are added in a session (see AddCombatantSheet), and can also be
/// created directly here.
struct PresetListView: View {
    let presetStore: PresetStore

    @State private var presets: [CreaturePreset] = []
    @State private var editingPreset: CreaturePreset?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if presets.isEmpty {
                ContentUnavailableView(
                    "No Creatures Yet",
                    systemImage: "pawprint",
                    description: Text("Add one here, or add a combatant during a session — it's saved here automatically.")
                )
            } else {
                List {
                    ForEach(presets) { preset in
                        Button(action: { editingPreset = preset }) {
                            HStack {
                                Text(preset.name)
                                    .font(.headline)
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    if let maxHP = preset.maxHP {
                                        Text("\(maxHP) HP")
                                            .font(.subheadline)
                                            .foregroundColor(Theme.textTertiary)
                                    }
                                    if let armorClass = preset.armorClass {
                                        Text("AC \(armorClass)")
                                            .font(.subheadline)
                                            .foregroundColor(Theme.textTertiary)
                                    }
                                    if let bonus = preset.initiativeBonus {
                                        Text("Initiative Bonus \(bonus >= 0 ? "+" : "")\(bonus)")
                                            .font(.caption)
                                            .foregroundColor(Theme.textTertiary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Theme.background)
                        .swipeActions(edge: .trailing) {
                            // No extra confirmation dialog: swipe-to-reveal + tap
                            // Delete is already two deliberate actions.
                            Button(role: .destructive) {
                                presetStore.delete(id: preset.id)
                                presets = presetStore.listPresets()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Creatures")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { editingPreset = CreaturePreset(name: "") }) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New Creature")
            }
        }
        .onAppear { presets = presetStore.listPresets() }
        .sheet(item: $editingPreset) { preset in
            EditPresetView(presetStore: presetStore, preset: preset) {
                presets = presetStore.listPresets()
            }
        }
    }
}

private struct EditPresetView: View {
    let presetStore: PresetStore
    let preset: CreaturePreset
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var hpText: String
    @State private var acText: String
    @State private var bonusText: String

    init(presetStore: PresetStore, preset: CreaturePreset, onSave: @escaping () -> Void) {
        self.presetStore = presetStore
        self.preset = preset
        self.onSave = onSave
        _name = State(initialValue: preset.name)
        _hpText = State(initialValue: preset.maxHP.map(String.init) ?? "")
        _acText = State(initialValue: preset.armorClass.map(String.init) ?? "")
        _bonusText = State(initialValue: preset.initiativeBonus.map(String.init) ?? "")
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                Form {
                    Section("Name") {
                        TextField("Name", text: $name)
                    }
                    Section("Max HP") {
                        TextField("Optional", text: $hpText)
                            .keyboardType(.numberPad)
                    }
                    Section("Armor Class") {
                        TextField("Optional", text: $acText)
                            .keyboardType(.numberPad)
                    }
                    Section("Initiative Bonus") {
                        TextField("Optional, added to random rolls", text: $bonusText)
                            .keyboardType(.numbersAndPunctuation)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(preset.name.isEmpty ? "New Creature" : "Edit Creature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var updated = preset
                        updated.name = name.trimmingCharacters(in: .whitespaces)
                        updated.maxHP = Int(hpText)
                        updated.armorClass = Int(acText)
                        updated.initiativeBonus = Int(bonusText)
                        guard !updated.name.isEmpty else { return }
                        presetStore.save(updated)
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PresetListView(presetStore: PresetStore())
    }
}
