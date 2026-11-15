import SwiftUI

/// The Character switch, used wherever a creature is made or copied. Off is a
/// creature, which dies the moment it reaches 0 HP. On is a character, which rolls
/// death saves instead. The label is the same everywhere; the line under it says
/// who the switch is for.
struct CharacterKindPicker: View {
    @Binding var isCharacter: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Toggle(isOn: $isCharacter) {
                Text("Character")
                    .font(Theme.Typography.rowTitle)
                    .foregroundColor(Theme.textPrimary)
            }
            .tint(Theme.accent)
            Text("Player character or friendly NPC")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.textSecondary)
        }
    }
}

#Preview {
    Form {
        Section { CharacterKindPicker(isCharacter: .constant(true)) }
    }
}
