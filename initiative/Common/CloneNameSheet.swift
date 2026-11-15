import SwiftUI

/// Asks for the name of a copy before making it. Clone stays disabled until the
/// name is usable, so a copy can't be made without one, and the owner always
/// types the name themselves. Used by both the creature and encounter screens.
struct CloneNameSheet: View {
    let title: String
    let existingNames: [String]
    let onClone: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

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
