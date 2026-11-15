import SwiftUI

/// Creature or Character, for a creature that is being made or copied. A creature
/// dies the moment it reaches 0 HP. A character, a player or an NPC that should
/// survive the same way, rolls death saves instead. The info under the choice
/// says which, so the owner doesn't need to know the rule to pick.
struct CharacterKindPicker: View {
    @Binding var isCharacter: Bool

    var body: some View {
        Picker("Kind", selection: $isCharacter) {
            Text("Creature").tag(false)
            Text("Character").tag(true)
        }
        .pickerStyle(.segmented)

        Text(isCharacter
             ? "Character: at 0 HP it rolls death saves, like a player. Use for players and NPCs that should not die instantly."
             : "Creature: at 0 HP it dies at once. Use for monsters and most NPCs.")
            .font(Theme.Typography.caption)
            .foregroundColor(Theme.textTertiary)
    }
}

#Preview {
    Form {
        Section { CharacterKindPicker(isCharacter: .constant(false)) }
    }
}
