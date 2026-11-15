import SwiftUI

/// Browse, open and delete creature presets. Presets accumulate automatically as
/// combatants are added in a session (see AddCombatantSheet), and can also be
/// created here. Opening a row pushes its detail screen (`CreatureDetailView`).
struct PresetListView: View {
    let presetStore: PresetStore

    // Seeded eagerly from the store rather than defaulting to `[]` and
    // filling in via `.onAppear` — an empty-then-populated flip flips
    // `appSearchable`'s `isVisible` from false to true right after the first
    // frame, which mounts `.searchable` for the first time on a *later*
    // render instead of the first one. Loading here means `.searchable` is
    // present, correctly, from frame one.
    @State private var presets: [CreaturePreset]
    @State private var creatingNew = false
    @State private var openPreset: CreaturePreset?
    @State private var pendingDelete: CreaturePreset?
    @State private var query = ""

    init(presetStore: PresetStore) {
        self.presetStore = presetStore
        _presets = State(initialValue: presetStore.listPresets())
    }

    private var matches: [CreaturePreset] {
        presets.filter { ListSections.matches(query: query, in: $0.searchableText) }
    }

    var body: some View {
        Group {
            if presets.isEmpty {
                ContentUnavailableView(
                    "No Creatures Yet",
                    systemImage: "pawprint",
                    description: Text("Add one here, or add a combatant during a session — it's saved here automatically.")
                )
            } else if matches.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                let groups = ListSections.split(matches, isBuiltIn: \.isBuiltIn)
                List {
                    section("Yours", presets: groups.mine)
                    section("Included", presets: groups.builtIn)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollDismissesKeyboard(.interactively)
            }
        }
        .appSearchable(text: $query, prompt: "Search creatures", isVisible: !presets.isEmpty)
        .themedScreen()
        .navigationTitle("Creatures")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { creatingNew = true }) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New Creature")
            }
        }
        .onAppear { reload() }
        .navigationDestination(item: $openPreset) { preset in
            CreatureDetailView(presetStore: presetStore, preset: preset, onChange: reload)
        }
        .navigationDestination(isPresented: $creatingNew) {
            CreatureDetailView(presetStore: presetStore, preset: CreaturePreset(name: ""), onChange: reload)
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

    private func reload() {
        presets = presetStore.listPresets()
    }

    /// Hidden entirely when empty rather than shown as a bare header — a "Yours"
    /// heading over nothing reads as something having gone missing.
    ///
    /// The title is a plain row inside the section, not `Section`'s own
    /// `header:` — a `List` in `.plain` style pins that header slot so it
    /// floats and follows the scroll instead of moving with its rows.
    @ViewBuilder
    private func section(_ title: String, presets sectionPresets: [CreaturePreset]) -> some View {
        if !sectionPresets.isEmpty {
            Section {
                Text(title)
                    .sectionLabel()
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                ForEach(sectionPresets) { preset in
                    Button(action: { openPreset = preset }) {
                        HStack(spacing: Theme.Spacing.md) {
                            Text(preset.name)
                                .font(Theme.Typography.rowTitle)
                                .foregroundColor(Theme.textPrimary)
                            Spacer(minLength: Theme.Spacing.sm)
                            // Fixed-width columns so each stat lines up down the list.
                            // A missing stat keeps its column, shown as a dash.
                            HStack(spacing: Theme.Spacing.md) {
                                statColumn("heart.fill", preset.maxHP.map(String.init), color: Theme.statusBad)
                                statColumn("shield.fill", preset.armorClass.map(String.init), color: Theme.statusInfo)
                                statColumn("die.face.5.fill", preset.initiativeBonus.map { $0 >= 0 ? "+\($0)" : "\($0)" }, color: Theme.textSecondary)
                            }
                        }
                    }
                    .buttonStyle(CardRowButtonStyle())
                    .cardRowLayout()
                    // Built-in creatures are fixtures: they can't be deleted or
                    // edited, and they can't be swiped at all. Copying is done on
                    // the detail screen, where the name is asked for first.
                    .swipeActions(edge: .trailing) {
                        if !preset.isBuiltIn {
                            Button(role: .destructive) {
                                pendingDelete = preset
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
    }

    private func statColumn(_ systemImage: String, _ value: String?, color: Color) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: systemImage)
                .font(Theme.Typography.iconInline)
                .frame(width: 12)
            Text(value ?? "–")
        }
        .font(Theme.Typography.stat)
        .foregroundColor(value == nil ? Theme.textTertiary : color)
        .frame(width: Theme.Layout.statColumn, alignment: .trailing)
    }
}

#Preview {
    NavigationStack {
        PresetListView(presetStore: PresetStore())
    }
}
