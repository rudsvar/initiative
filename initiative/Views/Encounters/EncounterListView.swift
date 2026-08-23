import SwiftUI

/// Create/edit/delete pre-made named encounters ahead of time, so a session can
/// start already populated with a prepared creature list instead of adding
/// combatants one at a time at the table. Starting a session from one is done
/// from the Main Menu's "New Session" chooser, not from here.
struct EncounterListView: View {
    let encounterStore: EncounterStore
    let presetStore: PresetStore

    @State private var encounters: [Encounter] = []
    @State private var editingEncounter: Encounter?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            if encounters.isEmpty {
                ContentUnavailableView(
                    "No Encounters Yet",
                    systemImage: "shield.lefthalf.filled",
                    description: Text("Prepare a named list of creatures ahead of time to start a session with.")
                )
            } else {
                List {
                    ForEach(encounters) { encounter in
                        Button(action: { editingEncounter = encounter }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(encounter.name)
                                    .font(.headline)
                                    .foregroundColor(Theme.textPrimary)
                                Text(summary(for: encounter))
                                    .font(.caption)
                                    .foregroundColor(Theme.textTertiary)
                            }
                        }
                        .cardRowStyle()
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                encounterStore.delete(id: encounter.id)
                                encounters = encounterStore.listEncounters()
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
        .navigationTitle("Encounters")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { editingEncounter = Encounter(name: "") }) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New Encounter")
            }
        }
        .onAppear { encounters = encounterStore.listEncounters() }
        .sheet(item: $editingEncounter) { encounter in
            EditEncounterView(encounterStore: encounterStore, presetStore: presetStore, encounter: encounter) {
                encounters = encounterStore.listEncounters()
            }
        }
    }

    private func summary(for encounter: Encounter) -> String {
        guard !encounter.entries.isEmpty else { return "No creatures yet" }
        return encounter.entries
            .map { $0.count > 1 ? "\($0.count)x \($0.name)" : $0.name }
            .joined(separator: ", ")
    }
}

private struct EditEncounterView: View {
    let encounterStore: EncounterStore
    let presetStore: PresetStore
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var encounter: Encounter
    @State private var showAddEntry = false

    init(encounterStore: EncounterStore, presetStore: PresetStore, encounter: Encounter, onSave: @escaping () -> Void) {
        self.encounterStore = encounterStore
        self.presetStore = presetStore
        self.onSave = onSave
        _encounter = State(initialValue: encounter)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                Form {
                    Section("Name") {
                        TextField(text: $encounter.name) {
                            Text("Encounter name").foregroundColor(Theme.placeholderText)
                        }
                    }

                    Section("Creatures") {
                        if encounter.entries.isEmpty {
                            Text("No creatures added yet")
                                .foregroundColor(Theme.textTertiary)
                        } else {
                            ForEach(encounter.entries) { entry in
                                HStack {
                                    Text(entry.count > 1 ? "\(entry.count)x \(entry.name)" : entry.name)
                                    Spacer()
                                    if let maxHP = entry.maxHP {
                                        Text("\(maxHP) HP")
                                            .font(.caption)
                                            .foregroundColor(Theme.textTertiary)
                                    }
                                }
                            }
                            .onDelete { encounter.entries.remove(atOffsets: $0) }
                        }

                        Button(action: { showAddEntry = true }) {
                            Label("Add Creature", systemImage: "plus.circle.fill")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .listRowBackground(Theme.inputBackground)
            }
            .navigationTitle("Edit Encounter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = encounter.name.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        encounter.name = trimmed
                        encounterStore.save(encounter)
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(encounter.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showAddEntry) {
                AddEncounterEntryView(presetStore: presetStore) { entry in
                    encounter.entries.append(entry)
                }
            }
        }
    }
}

private struct AddEncounterEntryView: View {
    let presetStore: PresetStore
    let onAdd: (EncounterEntry) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var hpText = ""
    @State private var acText = ""
    @State private var countText = ""
    @State private var matchedPresetBonus: Int?
    @State private var presets: [CreaturePreset] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
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
                }
                .scrollContentBackground(.hidden)
                .listRowBackground(Theme.inputBackground)
            }
            .navigationTitle("Add Creature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addEntry() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { presets = presetStore.listPresets() }
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
        if hpText.isEmpty, let maxHP = preset.maxHP { hpText = String(maxHP) }
        if acText.isEmpty, let armorClass = preset.armorClass { acText = String(armorClass) }
        matchedPresetBonus = preset.initiativeBonus
    }

    private func addEntry() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let entry = EncounterEntry(
            name: trimmedName,
            maxHP: Int(hpText),
            armorClass: Int(acText),
            initiativeBonus: matchedPresetBonus,
            count: max(1, Int(countText) ?? 1)
        )
        onAdd(entry)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        EncounterListView(encounterStore: EncounterStore(), presetStore: PresetStore())
    }
}
