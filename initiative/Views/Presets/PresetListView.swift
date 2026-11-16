import SwiftUI

/// Browse, open and delete one library: characters or creatures. Both come from the
/// same saved store and differ only in the kind flag, so the two screens are this
/// one view with a different kind. Presets accumulate automatically as combatants
/// are added in a session (see AddCombatantSheet), and can also be created here.
/// Opening a row pushes its detail screen (`CreatureDetailView`).
struct PresetListView: View {
    let presetStore: PresetStore
    /// True for the Characters library, false for Creatures.
    let characters: Bool
    /// Set when the list is used to choose an entry (the add-combatant sheet) rather
    /// than to browse: tapping a row, or cloning one, hands it over and closes the
    /// screen. Nothing is opened, created or deleted from here then.
    var onPick: ((CreaturePreset) -> Void)?

    @Environment(\.dismiss) private var dismiss
    // Seeded eagerly from the store rather than defaulting to `[]` and
    // filling in via `.onAppear` — an empty-then-populated flip mounts
    // `.searchable` on a *later* render instead of the first one.
    // Holds every saved entry: the Characters screen also lists the creatures,
    // because that is where its characters are cloned from.
    @State private var presets: [CreaturePreset]
    @State private var creatingNew = false
    @State private var openPreset: CreaturePreset?
    @State private var pendingDelete: CreaturePreset?
    @State private var cloning: CreaturePreset?
    @State private var query = ""

    init(presetStore: PresetStore, characters: Bool, onPick: ((CreaturePreset) -> Void)? = nil) {
        self.presetStore = presetStore
        self.characters = characters
        self.onPick = onPick
        _presets = State(initialValue: presetStore.listPresets())
    }

    private var noun: String { characters ? "Character" : "Creature" }

    private func matching(_ items: [CreaturePreset]) -> [CreaturePreset] {
        items.filter { ListSections.matches(query: query, in: $0.searchableText) }
    }

    /// The owner's own entries of this screen's kind.
    private var mine: [CreaturePreset] {
        presets.filter { !$0.isBuiltIn && $0.isPlayer == characters }
    }

    /// Creatures: the ones that shipped with the app. Characters: every creature,
    /// the owner's too, since any of them can be cloned into a character.
    private var allCreatures: [CreaturePreset] {
        presets.filter { !$0.isPlayer && (characters || $0.isBuiltIn) }
    }

    var body: some View {
        let shownMine = matching(mine)
        let shownCreatures = matching(allCreatures)
        return Group {
            if shownMine.isEmpty && shownCreatures.isEmpty && !query.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                List {
                    Text("Your \(noun.lowercased())s")
                        .sectionLabel()
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    if mine.isEmpty {
                        Text(characters
                            ? "No characters yet. Clone a creature from the list below."
                            : "No creatures of your own yet. Clone one from the list below, or add a new one.")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.textTertiary)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                    rows(shownMine)

                    Text("All creatures")
                        .sectionLabel()
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    rows(shownCreatures)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .sharedStatColumns()
            }
        }
        .appSearchable(text: $query, prompt: "Search \(noun.lowercased())s", isVisible: !presets.isEmpty)
        .themedScreen()
        .navigationTitle(characters ? "Characters" : "Creatures")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if onPick == nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { creatingNew = true }) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New \(noun)")
                }
            }
        }
        .onAppear { reload() }
        .navigationDestination(item: $openPreset) { preset in
            CreatureDetailView(presetStore: presetStore, preset: preset, onChange: reload)
        }
        .navigationDestination(isPresented: $creatingNew) {
            CreatureDetailView(presetStore: presetStore, preset: CreaturePreset(name: "", isPlayer: characters), onChange: reload)
        }
        .sheet(item: $cloning) { source in
            CloneNameSheet(title: "Clone \(source.name)", existingNames: presets.map(\.name), stats: CloneStats(source)) { newName, stats in
                let copy = presetStore.clone(source, named: newName, isPlayer: characters, stats: stats)
                reload()
                if onPick != nil { pick(copy) }
            }
        }
        .alert(
            "Delete creature?",
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
            presenting: pendingDelete
        ) { preset in
            Button("Delete", role: .destructive) {
                presetStore.delete(id: preset.id)
                reload()
            }
            Button("Cancel", role: .cancel) {}
        } message: { preset in
            Text("\(preset.name) will be removed. This can't be undone.")
        }
    }

    private func pick(_ preset: CreaturePreset) {
        onPick?(preset)
        dismiss()
    }

    private func reload() {
        presets = presetStore.listPresets()
    }

    @ViewBuilder
    private func rows(_ items: [CreaturePreset]) -> some View {
        ForEach(items) { preset in
            CloneableRow(open: { if onPick != nil { pick(preset) } else { openPreset = preset } }, clone: { cloning = preset }) {
                PresetRowLabel(preset: preset)
            }
            // Built-in creatures are fixtures: they can't be deleted or edited, and
            // they can't be swiped at all.
            .swipeActions(edge: .trailing) {
                if !preset.isBuiltIn && onPick == nil {
                    Button(role: .destructive) {
                        pendingDelete = preset
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .tint(Theme.deleteAction)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PresetListView(presetStore: PresetStore(), characters: false)
    }
}
