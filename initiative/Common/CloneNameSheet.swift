import SwiftUI

/// Asks for the name of a copy before making it. Clone stays disabled until the
/// name is usable, so a copy is never made without one. Used by every library
/// screen; the kind of the copy comes from the screen, so it is never asked.
struct CloneNameSheet: View {
    let title: String
    let existingNames: [String]
    /// Called with the trimmed name.
    let onClone: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
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
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { nameFocused = true }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Clone") {
                        onClone(trimmed)
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
    CloneNameSheet(title: "Clone Creature", existingNames: ["Goblin"]) { _ in }
}
