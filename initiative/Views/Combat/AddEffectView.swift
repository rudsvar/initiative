import SwiftUI

struct AddEffectView: View {
    let session: CombatSession
    let combatant: Combatant
    @Binding var isPresented: Bool
    @State private var effectName = ""
    @State private var selectedDurationType: DurationTypeSelection = .untilStartOfTheirTurn
    @State private var turnsCount = 1

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                Form {
                    Section("Condition") {
                        Menu {
                            ForEach(ConditionLibrary.all) { condition in
                                Button {
                                    effectName = condition.name
                                } label: {
                                    Label(condition.name, systemImage: condition.symbolName)
                                }
                            }
                        } label: {
                            HStack {
                                Text("Choose Condition")
                                Spacer()
                                if let matched = ConditionLibrary.matching(name: effectName) {
                                    Label(matched.name, systemImage: matched.symbolName)
                                        .foregroundColor(matched.color)
                                } else {
                                    Text("Custom")
                                        .foregroundColor(Theme.textTertiary)
                                }
                            }
                        }
                    }

                    Section("Effect Name") {
                        TextField(text: $effectName) {
                            Text("e.g., Stunned, Poisoned").foregroundColor(Theme.placeholderText)
                        }
                    }

                    Section("Duration") {
                        Picker("Duration", selection: $selectedDurationType) {
                            Text("Until start of their turn").tag(DurationTypeSelection.untilStartOfTheirTurn)
                            Text("Until end of their turn").tag(DurationTypeSelection.untilEndOfTheirTurn)
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()

                        Stepper("Turns: \(turnsCount)", value: $turnsCount, in: 1...20)
                    }
                }
                .scrollContentBackground(.hidden)
                .listRowBackground(Theme.inputBackground)
            }
            .navigationTitle("Add Effect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addEffect()
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                    .disabled(effectName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func addEffect() {
        let trimmedName = effectName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let durationType: DurationType
        switch selectedDurationType {
        case .untilStartOfTheirTurn:
            durationType = .untilStartOfTheirTurn(remainingTurns: turnsCount)
        case .untilEndOfTheirTurn:
            durationType = .untilEndOfTheirTurn(remainingTurns: turnsCount)
        }

        let effect = Effect(name: trimmedName, durationType: durationType)

        if let index = session.combatants.firstIndex(where: { $0.id == combatant.id }) {
            session.combatants[index].effects.append(effect)
        }
    }
}

enum DurationTypeSelection: Equatable, Hashable {
    case untilStartOfTheirTurn
    case untilEndOfTheirTurn
}

#Preview {
    let session = CombatSession()
    session.addCombatant(name: "Player", initiative: 20)
    session.addCombatant(name: "Enemy", initiative: 15)

    return AddEffectView(
        session: session,
        combatant: session.combatants.first!,
        isPresented: .constant(true)
    )
}
