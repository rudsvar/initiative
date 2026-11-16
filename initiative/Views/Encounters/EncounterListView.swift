import SwiftUI

/// Create/edit/delete pre-made named encounters ahead of time, so a session can
/// start already populated with a prepared creature list instead of adding
/// combatants one at a time at the table. Starting a session from one is done
/// from the Main Menu's "New Session" chooser, not from here.
struct EncounterListView: View {
    let encounterStore: EncounterStore
    let presetStore: PresetStore

    // Seeded eagerly rather than defaulting to `[]` and filling in via
    // `.onAppear` — see the matching note on `PresetListView`: an
    // empty-then-populated flip mounts `.searchable` for the first time on a
    // later render instead of the first one, which is what reads as the
    // search field's text doing a tiny resize on load.
    @State private var encounters: [Encounter]
    @State private var editingEncounter: Encounter?
    @State private var cloning: Encounter?
    @State private var query = ""

    init(encounterStore: EncounterStore, presetStore: PresetStore) {
        self.encounterStore = encounterStore
        self.presetStore = presetStore
        _encounters = State(initialValue: encounterStore.listEncounters())
    }

    private var matches: [Encounter] {
        encounters.filter { ListSections.matchesAny(query: query, in: $0.searchableText) }
    }

    var body: some View {
        Group {
            if encounters.isEmpty {
                ContentUnavailableView(
                    "No Encounters Yet",
                    systemImage: "shield.lefthalf.filled",
                    description: Text("Prepare a named list of creatures ahead of time to start a session with.")
                )
            } else if matches.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                let groups = ListSections.split(matches, isBuiltIn: \.isBuiltIn)
                List {
                    section("Your encounters", encounters: groups.mine)
                    section("All encounters", encounters: groups.builtIn)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .appSearchable(text: $query, prompt: "Search encounters or creatures", isVisible: !encounters.isEmpty)
        .themedScreen()
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
        .sheet(item: $cloning) { source in
            CloneNameSheet(title: "Clone \(source.name)", existingNames: encounters.map(\.name)) { newName, _ in
                encounterStore.clone(source, named: newName)
                encounters = encounterStore.listEncounters()
            }
        }
        .sheet(item: $editingEncounter) { encounter in
            EditEncounterView(encounterStore: encounterStore, presetStore: presetStore, encounter: encounter) {
                encounters = encounterStore.listEncounters()
            }
        }
    }

    /// Hidden entirely when empty rather than shown as a bare header — see the
    /// matching helper on the Creatures screen, which both lists mirror.
    ///
    /// The title is a plain row inside the section, not `Section`'s own
    /// `header:` — a `List` in `.plain` style pins that header slot so it
    /// floats and follows the scroll instead of moving with its rows.
    @ViewBuilder
    private func section(_ title: String, encounters sectionEncounters: [Encounter]) -> some View {
        if !sectionEncounters.isEmpty {
            Section {
                Text(title)
                    .sectionLabel()
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                ForEach(sectionEncounters) { encounter in
                    CloneableRow(open: { editingEncounter = encounter }, clone: { cloning = encounter }) {
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text(encounter.name)
                                .font(Theme.Typography.rowTitle)
                                .foregroundColor(Theme.textPrimary)
                            if let worth = worth(of: encounter) {
                                Text(worth)
                                    .font(Theme.Typography.caption)
                                    .foregroundColor(Theme.textTertiary)
                            }
                            Text(summary(for: encounter))
                                .font(Theme.Typography.caption)
                                .foregroundColor(Theme.textTertiary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    // Built-in encounters are fixtures: they can't be deleted, and
                    // they can't be swiped at all. Same rule as the Creatures screen.
                    .swipeActions(edge: .trailing) {
                        if !encounter.isBuiltIn {
                            Button(role: .destructive) {
                                encounterStore.delete(id: encounter.id)
                                encounters = encounterStore.listEncounters()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .tint(Theme.deleteAction)
                        }
                    }
                }
            }
        }
    }

    private func worth(of encounter: Encounter) -> String? {
        encounter.worthText(presetStore: presetStore)
    }

    private func summary(for encounter: Encounter) -> String {
        guard !encounter.entries.isEmpty else { return "No creatures yet" }
        return encounter.entries
            .map { $0.count > 1 ? "\($0.count)x \($0.name)" : $0.name }
            .joined(separator: ", ")
    }
}

/// Doubles as the read-only view of a built-in encounter — see the equivalent
/// note on the Creatures screen's sheet.
private struct EditEncounterView: View {
    let encounterStore: EncounterStore
    let presetStore: PresetStore
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var encounter: Encounter
    @State private var showAddEntry = false

    /// Fixed at presentation time from the encounter as saved, *not* from the
    /// editable `@State` copy — otherwise typing over a built-in's name in the
    /// disabled field (were it ever possible) would flip the screen out of
    /// read-only mid-edit.
    private let isReadOnly: Bool

    init(encounterStore: EncounterStore, presetStore: PresetStore, encounter: Encounter, onSave: @escaping () -> Void) {
        self.encounterStore = encounterStore
        self.presetStore = presetStore
        self.onSave = onSave
        self.isReadOnly = encounter.isBuiltIn
        _encounter = State(initialValue: encounter)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                Form {
                    Section("Name") {
                        TextField(text: $encounter.name) {
                            Text("Encounter name").foregroundColor(Theme.placeholderText)
                        }
                    }
                    .listRowBackground(Theme.surfaceRaised)

                    if let worth = encounter.worthText(presetStore: presetStore) {
                        Section {
                            Text(worth)
                                .font(Theme.Typography.caption)
                                .foregroundColor(Theme.textTertiary)
                        }
                        .listRowBackground(Theme.surfaceRaised)
                    }

                    Section("Creatures") {
                        if encounter.entries.isEmpty {
                            Text("No creatures added yet")
                                .foregroundColor(Theme.textTertiary)
                        } else {
                            ForEach(encounter.entries) { entry in
                                PresetRowLabel(preset: presetStore.overview(of: entry), count: entry.count)
                            }
                            .onDelete { encounter.entries.remove(atOffsets: $0) }
                        }

                        if !isReadOnly {
                            Button(action: { showAddEntry = true }) {
                                Label("Add Creature", systemImage: "plus")
                            }
                        }
                    }
                    .listRowBackground(Theme.surfaceRaised)
                }
                // Row background goes on each Section, never on the Form:
                // attached to the Form it is silently ignored, which is why
                // every one of these was rendering system grey in all nine themes.
                .scrollContentBackground(.hidden)
                .sharedStatColumns()
                // Read-only on the fields, not `.disabled` on the screen: a disabled
                // view stops scrolling, so a built-in's creatures could not be read.
                .environment(\.isEnabled, !isReadOnly)
            }
            .navigationTitle(isReadOnly ? encounter.name : "Edit Encounter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isReadOnly ? "Done" : "Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if !isReadOnly {
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
                        .listRowBackground(Theme.surfaceRaised)
                    }

                    Section("Name") {
                        TextField(text: $name) {
                            Text("Combatant name").foregroundColor(Theme.placeholderText)
                        }
                            .onChange(of: name) { _, newValue in
                                prefillFromPreset(named: newValue)
                            }
                    }
                    .listRowBackground(Theme.surfaceRaised)
                    Section("Max HP") {
                        TextField(text: $hpText) {
                            Text("Optional").foregroundColor(Theme.placeholderText)
                        }
                            .keyboardType(.numberPad)
                    }
                    .listRowBackground(Theme.surfaceRaised)
                    Section("Armor Class") {
                        TextField(text: $acText) {
                            Text("Optional").foregroundColor(Theme.placeholderText)
                        }
                            .keyboardType(.numberPad)
                    }
                    .listRowBackground(Theme.surfaceRaised)
                    Section("Count") {
                        TextField(text: $countText) {
                            Text("1").foregroundColor(Theme.placeholderText)
                        }
                            .keyboardType(.numberPad)
                    }
                    .listRowBackground(Theme.surfaceRaised)
                }
                // Row background goes on each Section, never on the Form:
                // attached to the Form it is silently ignored, which is why
                // every one of these was rendering system grey in all nine themes.
                .scrollContentBackground(.hidden)
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

extension Encounter {
    /// "CR 3 · 900 XP", with a note when some creatures have no rating. The same
    /// wording the creature rows use. Nil when nothing in it has a rating.
    func worthText(presetStore: PresetStore) -> String? {
        let result = EncounterXP.estimate(for: self) { presetStore.preset(named: $0)?.effectiveXP }
        guard let rating = result.estimatedRating else { return nil }
        let note = result.unratedCount > 0 ? " · \(result.unratedCount) unrated" : ""
        return "CR \(rating) · \(result.totalXP) XP\(note)"
    }
}

extension PresetStore {
    /// An encounter entry shown like a library row: the numbers saved on the entry,
    /// falling back to the creature's own, plus its rating.
    func overview(of entry: EncounterEntry) -> CreaturePreset {
        let known = preset(named: entry.name)
        return CreaturePreset(
            name: entry.name,
            maxHP: entry.maxHP ?? known?.maxHP,
            armorClass: entry.armorClass ?? known?.armorClass,
            initiativeBonus: entry.initiativeBonus ?? known?.initiativeBonus,
            isPlayer: known?.isPlayer ?? false,
            challengeRating: known?.effectiveChallengeRating
        )
    }
}
