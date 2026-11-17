import SwiftUI

/// The add-a-creature form's sections, placed inside a `Form`: a Choose row, then
/// Name, Max HP, Armor Class and Count. Add Combatant and an encounter's Add
/// Creature both use it, with the same picker (`PresetListView`), so the two
/// cannot drift apart. The caller adds anything of its own below.
struct CombatantDraftFields: View {
    @Binding var draft: CombatantDraft
    let presetStore: PresetStore
    /// Add Combatant offers characters as well as creatures; an encounter holds
    /// only creatures.
    let offersCharacters: Bool

    @State private var choosingCharacter = false
    @State private var choosingCreature = false
    @FocusState private var nameFocused: Bool

    var body: some View {
        Section {
            // One row split in two, a list per kind instead of a switch: the kind is
            // whichever side you chose from.
            HStack(spacing: 0) {
                if offersCharacters {
                    chooseHalf(characters: true)
                    Rectangle()
                        .fill(Theme.border.opacity(0.5))
                        .frame(width: Theme.hairline)
                }
                chooseHalf(characters: false)
            }
        }
        .listRowBackground(Theme.surfaceRaised)
        .listRowInsets(EdgeInsets())

        Section("Name") {
            TextField(text: $draft.name) {
                Text("Combatant name").foregroundColor(Theme.placeholderText)
            }
            .focused($nameFocused)
            .onChange(of: draft.name) { _, newValue in
                draft.nameChanged(matching: presetStore.preset(named: newValue))
            }
        }
        .listRowBackground(Theme.surfaceRaised)
        .onAppear { nameFocused = true }

        numberSection("Max HP", text: $draft.hpText, placeholder: "Optional")
        numberSection("Armor Class", text: $draft.acText, placeholder: "Optional")
        numberSection("Count", text: $draft.countText, placeholder: "1")
    }

    private func numberSection(_ title: String, text: Binding<String>, placeholder: String) -> some View {
        Section(title) {
            TextField(text: text) {
                Text(placeholder).foregroundColor(Theme.placeholderText)
            }
            .keyboardType(.numberPad)
        }
        .listRowBackground(Theme.surfaceRaised)
    }

    /// One side of the split. The chosen entry's name shows on its own kind's side;
    /// the other side says Choose.
    private func chooseHalf(characters: Bool) -> some View {
        let isChosen = draft.chosen?.isPlayer == characters
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
                Text(isChosen ? (draft.chosen?.name ?? "Choose") : "Choose")
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
            PresetListView(presetStore: presetStore, characters: characters) { draft.choose($0) }
        }
    }
}
