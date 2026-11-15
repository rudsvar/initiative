import SwiftUI

/// Asks for the name of a copy before making it, and, for creatures, whether the
/// copy is a player character or an NPC. Clone stays disabled until the name is
/// usable, so a copy is never made without one. Used by the creature and
/// encounter screens; encounters have no character kind, so they skip that row.
struct CloneNameSheet: View {
    let title: String
    let existingNames: [String]
    /// Whether to ask for the character kind. Only creatures have one.
    var asksCharacterKind = false
    /// The kind the copy starts as: a clone of a character starts as one, and the
    /// owner can still switch it before cloning.
    var startsAsCharacter = false
    /// Called with the trimmed name and the chosen kind (`false` when not asked).
    let onClone: (String, Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var isCharacter = false
    /// The name box takes focus when the sheet opens, so the owner can type at once.
    @FocusState private var nameFocused: Bool

    private var trimmed: String { name.trimmingCharacters(in: .whitespaces) }
    private var isValid: Bool { CloneName.isValid(name, avoiding: existingNames) }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                Form {
                    Section {
                        TextField(text: $name) {
                            Text("Name").foregroundColor(Theme.placeholderText)
                        }
                        .focused($nameFocused)
                    } footer: {
                        if !trimmed.isEmpty && !isValid {
                            Text("Another entry already has that name.")
                                .foregroundColor(Theme.textTertiary)
                        }
                    }
                    .listRowBackground(Theme.surfaceRaised)

                    if asksCharacterKind {
                        Section {
                            CharacterKindPicker(isCharacter: $isCharacter)
                        }
                        .listRowBackground(Theme.surfaceRaised)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                nameFocused = true
                isCharacter = startsAsCharacter
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Clone") {
                        onClone(trimmed, isCharacter)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
        }
    }
}

#Preview {
    CloneNameSheet(title: "Clone Creature", existingNames: ["Goblin"], asksCharacterKind: true) { _, _ in }
}
