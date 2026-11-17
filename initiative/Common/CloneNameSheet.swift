import SwiftUI

/// Asks for the name of a copy before making it. Clone stays disabled until the
/// name is usable, so a copy is never made without one. Used by every library
/// screen; the kind of the copy comes from the screen, so it is never asked.
struct CloneNameSheet: View {
    let title: String
    let existingNames: [String]
    /// The numbers to offer for editing. Nil for encounters, which have none.
    var stats: CloneStats?
    /// Called with the trimmed name and the (possibly edited) numbers.
    let onClone: (String, CloneStats?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var hpText = ""
    @State private var acText = ""
    @State private var bonusText = ""
    @State private var challenge: String?
    /// The name box takes focus when the sheet opens, so the owner can type at once.
    @FocusState private var nameFocused: Bool

    private var trimmed: String { name.trimmingCharacters(in: .whitespaces) }
    private func statField(_ title: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        HStack {
            Text(title).foregroundColor(Theme.textPrimary)
            TextField(text: text) {
                Text("Optional").foregroundColor(Theme.placeholderText)
            }
            .keyboardType(keyboard)
            .multilineTextAlignment(.trailing)
        }
    }

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
                        NameTakenFooter(name: name, isAvailable: isValid)
                    }
                    .listRowBackground(Theme.surfaceRaised)

                    if stats != nil {
                        Section {
                            statField("Max HP", text: $hpText, keyboard: .numberPad)
                            statField("Armor Class", text: $acText, keyboard: .numberPad)
                            statField("Initiative Bonus", text: $bonusText, keyboard: .numbersAndPunctuation)
                            ChallengeRatingPicker(selection: $challenge)
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
                hpText = stats?.maxHP.map(String.init) ?? ""
                acText = stats?.armorClass.map(String.init) ?? ""
                bonusText = stats?.initiativeBonus.map(String.init) ?? ""
                challenge = stats?.challengeRating
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Clone") {
                        onClone(trimmed, stats == nil ? nil : CloneStats(maxHP: Int(hpText), armorClass: Int(acText), initiativeBonus: Int(bonusText), challengeRating: challenge))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
        }
    }
}

/// Says why Save or Clone is off when the typed name is already in use. Shows
/// nothing for a blank name, where the reason is plain.
struct NameTakenFooter: View {
    let name: String
    let isAvailable: Bool

    var body: some View {
        if !name.trimmingCharacters(in: .whitespaces).isEmpty && !isAvailable {
            Text("Another entry already has that name.")
                .foregroundColor(Theme.textTertiary)
        }
    }
}

#Preview {
    CloneNameSheet(title: "Clone Creature", existingNames: ["Goblin"], stats: CloneStats(maxHP: 7, armorClass: 15, initiativeBonus: 2, challengeRating: "1/4")) { _, _ in }
}
