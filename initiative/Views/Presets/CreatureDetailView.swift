import SwiftUI

/// One creature, pushed from the Creatures list. A built-in creature is read-only:
/// its full stat block when we have one, and Clone in the toolbar. A creature the
/// owner made is an editable form with Save.
struct CreatureDetailView: View {
    let presetStore: PresetStore
    let preset: CreaturePreset
    /// Called after a save or a clone, so the list reloads.
    let onChange: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var cloneNamePresented = false
    @State private var name: String
    @State private var hpText: String
    @State private var acText: String
    @State private var bonusText: String
    @State private var isPlayer: Bool

    init(presetStore: PresetStore, preset: CreaturePreset, onChange: @escaping () -> Void) {
        self.presetStore = presetStore
        self.preset = preset
        self.onChange = onChange
        _name = State(initialValue: preset.name)
        _hpText = State(initialValue: preset.maxHP.map(String.init) ?? "")
        _acText = State(initialValue: preset.armorClass.map(String.init) ?? "")
        _bonusText = State(initialValue: preset.initiativeBonus.map(String.init) ?? "")
        _isPlayer = State(initialValue: preset.isPlayer)
    }

    private var isBuiltIn: Bool { preset.isBuiltIn }

    /// The full stat block for a built-in SRD creature, when the app has one.
    private var block: StatBlock? {
        SRDCatalog.bundled.first { $0.name == preset.name }
    }

    var body: some View {
        Group {
            if isBuiltIn {
                builtInBody
            } else {
                editableForm
            }
        }
        .navigationTitle(isBuiltIn ? preset.name : (preset.name.isEmpty ? "New Creature" : "Edit Creature"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isBuiltIn {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Clone") { cloneNamePresented = true }
                        .fontWeight(.semibold)
                }
            } else {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .sheet(isPresented: $cloneNamePresented) {
            CloneNameSheet(
                title: "Clone Creature",
                existingNames: presetStore.listPresets().map(\.name),
                asksCharacterKind: true
            ) { newName, kind in
                presetStore.clone(preset, named: newName, isPlayer: kind)
                onChange()
                dismiss()
            }
        }
    }

    /// Scrolls, so the whole stat block can be read on a phone.
    private var builtInBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                if let block {
                    StatBlockSummary(block: block)
                } else {
                    // Built-ins without a stat block in the app: only the three numbers.
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text(preset.name).cardHeading()
                        Text("Hit Points \(preset.maxHP.map(String.init) ?? "–") · Armor \(preset.armorClass.map(String.init) ?? "–") · Initiative \(signed(preset.initiativeBonus))")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.textSecondary)
                        Text("Full stat block not in the app yet.")
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.textTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .sectionCard()
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .themedScreen()
    }

    private var editableForm: some View {
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

                Section("Initiative Bonus") {
                    TextField(text: $bonusText) {
                        Text("Optional, added to random rolls").foregroundColor(Theme.placeholderText)
                    }
                    .keyboardType(.numbersAndPunctuation)
                }
                .listRowBackground(Theme.surfaceRaised)

                Section {
                    CharacterKindPicker(isCharacter: $isPlayer)
                }
                .listRowBackground(Theme.surfaceRaised)
            }
            // Row background goes on each Section, never on the Form: attached to
            // the Form it is silently ignored.
            .scrollContentBackground(.hidden)
        }
    }

    private func save() {
        var updated = preset
        updated.name = name.trimmingCharacters(in: .whitespaces)
        updated.maxHP = Int(hpText)
        updated.armorClass = Int(acText)
        updated.initiativeBonus = Int(bonusText)
        updated.isPlayer = isPlayer
        guard !updated.name.isEmpty else { return }
        presetStore.save(updated)
        onChange()
        dismiss()
    }

    private func signed(_ n: Int?) -> String {
        guard let n else { return "–" }
        return n >= 0 ? "+\(n)" : "\(n)"
    }
}

#Preview {
    NavigationStack {
        CreatureDetailView(presetStore: PresetStore(), preset: CreaturePreset(name: "Goblin"), onChange: {})
    }
}
