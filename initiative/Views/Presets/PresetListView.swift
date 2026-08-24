import SwiftUI

/// Browse/edit/delete creature presets. Presets accumulate automatically as
/// combatants are added in a session (see AddCombatantSheet), and can also be
/// created directly here.
struct PresetListView: View {
    let presetStore: PresetStore

    @State private var presets: [CreaturePreset] = []
    @State private var editingPreset: CreaturePreset?

    var body: some View {
        Group {
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
                            HStack(spacing: Theme.Spacing.md) {
                                Text(preset.name)
                                    .font(Theme.Typography.rowTitle)
                                    .foregroundColor(Theme.textPrimary)
                                Spacer(minLength: Theme.Spacing.sm)
                                // Same icon-led stat column as the combatant row,
                                // so a creature reads the same wherever it appears.
                                VStack(alignment: .leading, spacing: 2) {
                                    if let maxHP = preset.maxHP {
                                        statRow("heart.fill", "\(maxHP)")
                                    }
                                    if let armorClass = preset.armorClass {
                                        statRow("shield.fill", "\(armorClass)")
                                    }
                                    if let bonus = preset.initiativeBonus, bonus != 0 {
                                        statRow("die.face.5.fill", "\(bonus >= 0 ? "+" : "")\(bonus)")
                                    }
                                }
                            }
                        }
                        .cardRowStyle()
                        .cardRowLayout()
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
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .themedScreen()
        .navigationTitle("Creatures")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { editingPreset = CreaturePreset(name: "") }) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New Creature")
            }
            // Restore Defaults lives behind the menu, not as a bare bar button:
            // it used to sit immediately beside Back, where a mistimed tap on the
            // way out of the screen silently repopulated the list.
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        presetStore.restoreMissingDefaults()
                        presets = presetStore.listPresets()
                    } label: {
                        Label("Restore Default Creatures", systemImage: "arrow.counterclockwise")
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                }
                .accessibilityLabel("Options")
            }
        }
        .onAppear { presets = presetStore.listPresets() }
        .sheet(item: $editingPreset) { preset in
            EditPresetView(presetStore: presetStore, preset: preset) {
                presets = presetStore.listPresets()
            }
        }
    }

    private func statRow(_ systemImage: String, _ text: String) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: systemImage)
                .font(.caption2)
                .frame(width: 12)
            Text(text)
        }
        .font(Theme.Typography.stat)
        .foregroundColor(Theme.textSecondary)
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
                Theme.backgroundGradient.ignoresSafeArea()
                Form {
                    Section("Name") {
                        TextField(text: $name) {
                            Text("Name").foregroundColor(Theme.placeholderText)
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
                    Section("Initiative Bonus") {
                        TextField(text: $bonusText) {
                            Text("Optional, added to random rolls").foregroundColor(Theme.placeholderText)
                        }
                            .keyboardType(.numbersAndPunctuation)
                    }
                }
                .scrollContentBackground(.hidden)
                .listRowBackground(Theme.surfaceRaised)
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
