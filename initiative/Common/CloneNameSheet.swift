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
    /// Called with the trimmed name and the chosen kind (`false` when not asked).
    let onClone: (String, Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var isPlayer = false

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
                    } footer: {
                        if !trimmed.isEmpty && !isValid {
                            Text("Another entry already has that name.")
                                .foregroundColor(Theme.textTertiary)
                        }
                    }
                    .listRowBackground(Theme.surfaceRaised)

                    if asksCharacterKind {
                        Section("Character") {
                            Picker("Character", selection: $isPlayer) {
                                Text("NPC").tag(false)
                                Text("Player").tag(true)
                            }
                            .pickerStyle(.segmented)
                            Text(isPlayer ? "Players roll death saves at 0 HP." : "Anything else simply dies at 0 HP.")
                                .font(Theme.Typography.caption)
                                .foregroundColor(Theme.textTertiary)
                        }
                        .listRowBackground(Theme.surfaceRaised)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Clone") {
                        onClone(trimmed, isPlayer)
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
