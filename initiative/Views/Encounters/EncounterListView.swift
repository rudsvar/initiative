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
    @State private var pendingDelete: Encounter?
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
                let hasOwn = encounters.contains { !$0.isBuiltIn }
                List {
                    LibrarySectionLabel(
                        title: "Your encounters",
                        emptyHint: hasOwn ? nil : "No encounters of your own yet. Clone one from the list below, or add a new one."
                    )
                    rows(groups.mine)
                    if !groups.builtIn.isEmpty {
                        LibrarySectionLabel(title: "All encounters")
                        rows(groups.builtIn)
                    }
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
        .deleteConfirmation($pendingDelete, noun: "encounter", name: \.name) { encounter in
            encounterStore.delete(id: encounter.id)
            encounters = encounterStore.listEncounters()
        }
        .sheet(item: $editingEncounter) { encounter in
            EditEncounterView(encounterStore: encounterStore, presetStore: presetStore, encounter: encounter) {
                encounters = encounterStore.listEncounters()
            }
        }
    }

    @ViewBuilder
    private func rows(_ sectionEncounters: [Encounter]) -> some View {
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
                        pendingDelete = encounter
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .tint(Theme.deleteAction)
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

    private var nameIsAvailable: Bool { encounterStore.isNameAvailable(encounter.name, excluding: encounter.id) }

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
                Form {
                    Section {
                        TextField(text: $encounter.name) {
                            Text("Encounter name").foregroundColor(Theme.placeholderText)
                        }
                    } header: {
                        Text("Name")
                    } footer: {
                        if !isReadOnly {
                            NameTakenFooter(name: encounter.name, isAvailable: nameIsAvailable)
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
            .themedScreen()
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
                        guard nameIsAvailable else { return }
                        encounter.name = trimmed
                        encounterStore.save(encounter)
                        onSave()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!nameIsAvailable)
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

/// An encounter's Add Creature: the same fields and picker as Add Combatant
/// (`CombatantDraftFields`), creatures only.
private struct AddEncounterEntryView: View {
    let presetStore: PresetStore
    let onAdd: (EncounterEntry) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft = CombatantDraft()

    var body: some View {
        NavigationStack {
            Form {
                CombatantDraftFields(draft: $draft, presetStore: presetStore, offersCharacters: false)
            }
            .scrollContentBackground(.hidden)
            .themedScreen()
            .navigationTitle("Add Creature")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addEntry() }
                        .fontWeight(.semibold)
                        .disabled(!draft.isValid)
                }
            }
        }
    }

    private func addEntry() {
        guard draft.isValid else { return }
        onAdd(EncounterEntry(
            name: draft.trimmedName,
            maxHP: draft.maxHP,
            armorClass: draft.armorClass,
            initiativeBonus: draft.initiativeBonus,
            count: draft.count
        ))
        dismiss()
    }
}

#Preview {
    NavigationStack {
        EncounterListView(encounterStore: EncounterStore(), presetStore: PresetStore())
    }
}

extension Encounter {
    /// "Total 900 XP", saying so when some of it is estimated. Nil when nothing in
    /// it has a value.
    func worthText(presetStore: PresetStore) -> String? {
        EncounterXP.estimate(for: self) { presetStore.overview(of: $0).challenge }.text
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
