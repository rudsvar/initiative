import SwiftUI

/// Browse/edit/delete creature presets. Presets accumulate automatically as
/// combatants are added in a session (see AddCombatantSheet), and can also be
/// created directly here.
struct PresetListView: View {
    let presetStore: PresetStore

    // Seeded eagerly from the store rather than defaulting to `[]` and
    // filling in via `.onAppear` — an empty-then-populated flip flips
    // `appSearchable`'s `isVisible` from false to true right after the first
    // frame, which mounts `.searchable` for the first time on a *later*
    // render instead of the first one. That cold mount is what animates in
    // and reads as the search field's text doing a tiny resize on load.
    // Loading here means `.searchable` is present, correctly, from frame one.
    @State private var presets: [CreaturePreset]
    @State private var editingPreset: CreaturePreset?
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
                    Button(action: { editingPreset = preset }) {
                        HStack(spacing: Theme.Spacing.md) {
                            Text(preset.name)
                                .font(Theme.Typography.rowTitle)
                                .foregroundColor(Theme.textPrimary)
                            Spacer(minLength: Theme.Spacing.sm)
                            // Icon-led like the combatant row, so a creature
                            // reads the same wherever it appears — but laid out
                            // across rather than stacked. Stacked, three stats
                            // make every row three lines tall, and at 70-odd
                            // creatures that costs more scrolling than the
                            // aligned columns are worth.
                            HStack(spacing: Theme.Spacing.md) {
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
                    .buttonStyle(CardRowButtonStyle())
                    .cardRowLayout()
                    // Built-in creatures are fixtures: they can't be deleted or
                    // edited, only copied. So a built-in row offers Duplicate
                    // where a user's own offers Delete, rather than offering
                    // actions that then refuse.
                    .swipeActions(edge: .trailing) {
                        if preset.isBuiltIn {
                            Button {
                                presetStore.duplicate(preset)
                                presets = presetStore.listPresets()
                            } label: {
                                Label("Duplicate", systemImage: "plus.square.on.square")
                            }
                        } else {
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
            }
        }
    }

    private func statRow(_ systemImage: String, _ text: String) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: systemImage)
                .font(Theme.Typography.iconInline)
                .frame(width: 12)
            Text(text)
        }
        .font(Theme.Typography.stat)
        .foregroundColor(Theme.textSecondary)
    }
}

/// Doubles as the read-only view of a built-in creature. Built-ins can't be
/// edited, but they still need to be *inspectable* — and showing the same fields
/// greyed out, with Duplicate where Save would be, makes the relationship between
/// the two obvious in a way a separate detail screen wouldn't.
private struct EditPresetView: View {
    let presetStore: PresetStore
    let preset: CreaturePreset
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var hpText: String
    @State private var acText: String
    @State private var bonusText: String
    @State private var isPlayer: Bool

    private var isReadOnly: Bool { preset.isBuiltIn }

    init(presetStore: PresetStore, preset: CreaturePreset, onSave: @escaping () -> Void) {
        self.presetStore = presetStore
        self.preset = preset
        self.onSave = onSave
        _name = State(initialValue: preset.name)
        _hpText = State(initialValue: preset.maxHP.map(String.init) ?? "")
        _acText = State(initialValue: preset.armorClass.map(String.init) ?? "")
        _bonusText = State(initialValue: preset.initiativeBonus.map(String.init) ?? "")
        _isPlayer = State(initialValue: preset.isPlayer)
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
                    Section("Type") {
                        Toggle("Player character", isOn: $isPlayer)
                            .tint(Theme.accent)
                        Text("Players roll death saves at 0 HP; anything else simply dies.")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.textTertiary)
                    }
                    .listRowBackground(Theme.surfaceRaised)

                    Section("Initiative Bonus") {
                        TextField(text: $bonusText) {
                            Text("Optional, added to random rolls").foregroundColor(Theme.placeholderText)
                        }
                            .keyboardType(.numbersAndPunctuation)
                    }
                    .listRowBackground(Theme.surfaceRaised)
                }
                // Row background goes on each Section, never on the Form:
                // attached to the Form it is silently ignored, which is why
                // every one of these was rendering system grey in all nine themes.
                .scrollContentBackground(.hidden)
            }
            .disabled(isReadOnly)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isReadOnly ? "Done" : "Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isReadOnly {
                        // The only way to customise a built-in. The copy lands in
                        // "Yours" at the top of the list, where it's editable.
                        Button("Duplicate") {
                            presetStore.duplicate(preset)
                            onSave()
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    } else {
                    Button("Save") {
                        var updated = preset
                        updated.name = name.trimmingCharacters(in: .whitespaces)
                        updated.maxHP = Int(hpText)
                        updated.armorClass = Int(acText)
                        updated.initiativeBonus = Int(bonusText)
                        updated.isPlayer = isPlayer
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

    private var navigationTitle: String {
        if isReadOnly { return preset.name }
        return preset.name.isEmpty ? "New Creature" : "Edit Creature"
    }
}

#Preview {
    NavigationStack {
        PresetListView(presetStore: PresetStore())
    }
}
