import SwiftUI

/// Full-screen modal for adding one or more combatants. Replaced an earlier inline
/// row design that was too easy to trigger by accident and too fiddly to hit the
/// small per-field controls — a native Form gives each field a full-size tap target.
struct AddCombatantSheet: View {
    let session: CombatSession
    let presetStore: PresetStore
    @Binding var isPresented: Bool

    @State private var name = ""
    @State private var initiativeText = ""
    @State private var hpText = ""
    @State private var acText = ""
    @State private var countText = ""
    @State private var matchedPresetBonus: Int?
    /// Defaults to NPC — most of what a DM adds mid-combat is something the party
    /// is fighting. Picking or typing a known creature's name adopts that
    /// creature's setting instead (see prefillFromPreset).
    @State private var isPlayer = false
    /// What was picked from a Choose list, if the name still is that. Typing a different
    /// name clears it, so the Choose rows never claim a name that was typed over.
    @State private var chosen: CreaturePreset?
    @State private var choosingCharacter = false
    @State private var choosingCreature = false
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                Form {
                    Section {
                        // One row split in two, a list per kind instead of a switch: the
                        // kind is whichever side you chose from. Choosing from one clears
                        // the other.
                        HStack(spacing: 0) {
                            chooseHalf(characters: true)
                            Rectangle()
                                .fill(Theme.border.opacity(0.5))
                                .frame(width: Theme.hairline)
                            chooseHalf(characters: false)
                        }
                    }
                    .listRowBackground(Theme.surfaceRaised)
                    .listRowInsets(EdgeInsets())

                    Section("Name") {
                        TextField(text: $name) {
                            Text("Combatant name").foregroundColor(Theme.placeholderText)
                        }
                            .focused($nameFieldFocused)
                            .onChange(of: name) { _, newValue in
                                if chosen?.name != newValue { chosen = nil }
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

                    Section("Initiative") {
                        TextField(text: $initiativeText) {
                            Text("Random 1–20 if left blank").foregroundColor(Theme.placeholderText)
                        }
                            .keyboardType(.numberPad)
                    }
                    .listRowBackground(Theme.surfaceRaised)

                    if (Int(countText) ?? 1) > 1 {
                        Section {
                            Text(
                                initiativeText.isEmpty
                                    ? "Each copy gets its own random initiative roll."
                                    : "All copies get this same initiative."
                            )
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.textTertiary)
                        }
                        .listRowBackground(Theme.surfaceRaised)
                    }
                }
                // Row background goes on each Section, never on the Form:
                // attached to the Form it is silently ignored, which is why
                // every one of these was rendering system grey in all nine themes.
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Add Combatant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addCombatant() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                nameFieldFocused = true
            }
        }
    }

    /// One side of the split. The chosen entry's name shows on its own kind's side; the
    /// other side says Choose.
    private func chooseHalf(characters: Bool) -> some View {
        let isChosen = chosen?.isPlayer == characters
        return Button {
            if characters { choosingCharacter = true } else { choosingCreature = true }
        } label: {
            VStack(spacing: Theme.Spacing.xxs) {
                Image(systemName: characters ? "person.fill" : "pawprint.fill")
                    .font(Theme.Typography.readoutIcon)
                    .foregroundColor(Theme.textTertiary)
                Text(characters ? "Character" : "Creature")
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.textSecondary)
                Text(isChosen ? (chosen?.name ?? "Choose") : "Choose")
                    .font(Theme.Typography.rowTitle)
                    .foregroundColor(isChosen ? Theme.textPrimary : Theme.textTertiary)
                    .lineLimit(1)
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .navigationDestination(isPresented: characters ? $choosingCharacter : $choosingCreature) {
            PresetListView(presetStore: presetStore, characters: characters) { selectPreset($0) }
        }
    }

    private func selectPreset(_ preset: CreaturePreset) {
        chosen = preset
        name = preset.name
        hpText = preset.maxHP.map(String.init) ?? ""
        acText = preset.armorClass.map(String.init) ?? ""
        matchedPresetBonus = preset.initiativeBonus
        isPlayer = preset.isPlayer
    }

    private func prefillFromPreset(named newName: String) {
        guard let preset = presetStore.preset(named: newName) else {
            matchedPresetBonus = nil
            // A name that matches nothing is a new creature, not whatever was picked before.
            isPlayer = false
            return
        }
        if hpText.isEmpty, let maxHP = preset.maxHP {
            hpText = String(maxHP)
        }
        if acText.isEmpty, let armorClass = preset.armorClass {
            acText = String(armorClass)
        }
        // Initiative bonus isn't a visible field here (edited only from Main Menu ->
        // Combatants) — it's applied silently to random rolls for a matched preset.
        matchedPresetBonus = preset.initiativeBonus
        isPlayer = preset.isPlayer
    }

    private func addCombatant() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let initiative = Int(initiativeText)
        let maxHP = Int(hpText)
        let armorClass = Int(acText)
        let count = max(1, Int(countText) ?? 1)
        let bonus = matchedPresetBonus ?? 0

        session.addCombatants(name: trimmedName, initiative: initiative, maxHP: maxHP, armorClass: armorClass, count: count, initiativeBonus: bonus, isPlayer: isPlayer)
        presetStore.upsert(name: trimmedName, maxHP: maxHP, armorClass: armorClass, isPlayer: isPlayer)

        isPresented = false
    }
}

#Preview {
    AddCombatantSheet(session: CombatSession(), presetStore: PresetStore(), isPresented: .constant(true))
}
