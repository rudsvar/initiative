import SwiftUI

/// Browse/edit/delete accumulated creature presets. Presets are created automatically
/// by adding combatants in a session (see AddCombatantSheet) — this screen manages
/// what's already there rather than authoring new ones from scratch.
struct PresetListView: View {
    let presetStore: PresetStore

    @State private var presets: [CreaturePreset] = []
    @State private var editingPreset: CreaturePreset?
    @State private var pendingDeletePreset: CreaturePreset?

    var body: some View {
        Group {
            if presets.isEmpty {
                ContentUnavailableView(
                    "No Creatures Yet",
                    systemImage: "pawprint",
                    description: Text("Combatants you add during a session are saved here automatically for reuse.")
                )
            } else {
                List {
                    ForEach(presets) { preset in
                        Button(action: { editingPreset = preset }) {
                            HStack {
                                Text(preset.name)
                                    .font(.headline)
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    if let maxHP = preset.maxHP {
                                        Text("\(maxHP) HP")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                    if let bonus = preset.initiativeBonus {
                                        Text("Initiative Bonus \(bonus >= 0 ? "+" : "")\(bonus)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .tint(.primary)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                pendingDeletePreset = preset
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Creatures")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { presets = presetStore.listPresets() }
        .sheet(item: $editingPreset) { preset in
            EditPresetView(presetStore: presetStore, preset: preset) {
                presets = presetStore.listPresets()
            }
        }
        .confirmationDialog(
            "Delete \"\(pendingDeletePreset?.name ?? "")\"?",
            isPresented: Binding(
                get: { pendingDeletePreset != nil },
                set: { if !$0 { pendingDeletePreset = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let preset = pendingDeletePreset {
                    presetStore.delete(id: preset.id)
                    presets = presetStore.listPresets()
                }
                pendingDeletePreset = nil
            }
            Button("Cancel", role: .cancel) {
                pendingDeletePreset = nil
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
    @State private var bonusText: String

    init(presetStore: PresetStore, preset: CreaturePreset, onSave: @escaping () -> Void) {
        self.presetStore = presetStore
        self.preset = preset
        self.onSave = onSave
        _name = State(initialValue: preset.name)
        _hpText = State(initialValue: preset.maxHP.map(String.init) ?? "")
        _bonusText = State(initialValue: preset.initiativeBonus.map(String.init) ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Name", text: $name)
                }
                Section("Max HP") {
                    TextField("Optional", text: $hpText)
                        .keyboardType(.numberPad)
                }
                Section("Initiative Bonus") {
                    TextField("Optional, added to random rolls", text: $bonusText)
                        .keyboardType(.numbersAndPunctuation)
                }
            }
            .navigationTitle("Edit Creature")
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
