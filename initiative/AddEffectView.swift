import SwiftUI

struct AddEffectView: View {
    let session: CombatSession
    let combatant: Combatant
    @Binding var isPresented: Bool
    @State private var effectName = ""
    @State private var selectedDurationType: DurationTypeSelection = .untilStartOfTheirTurn
    @State private var selectedTargetId: UUID?

    var body: some View {
        NavigationStack {
            Form {
                Section("Effect Name") {
                    TextField("e.g., Stunned, Poisoned", text: $effectName)
                }

                Section("Duration") {
                    Picker("Duration", selection: $selectedDurationType) {
                        Text("Until start of their next turn").tag(DurationTypeSelection.untilStartOfTheirTurn)
                        Text("Until end of their next turn").tag(DurationTypeSelection.untilEndOfTheirTurn)
                        Text("Until start of target's next turn").tag(DurationTypeSelection.untilStartOfTargetTurn)
                        Text("Until end of target's next turn").tag(DurationTypeSelection.untilEndOfTargetTurn)
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                    .onChange(of: selectedDurationType) { _, newValue in
                        if newValue.isTargetBased, selectedTargetId == nil {
                            selectedTargetId = session.combatants.first(where: { $0.id != combatant.id })?.id
                        } else if !newValue.isTargetBased {
                            selectedTargetId = nil
                        }
                    }
                }

                if selectedDurationType.isTargetBased {
                    Section("Target") {
                        Picker("Target", selection: $selectedTargetId) {
                            ForEach(
                                session.combatants.filter { $0.id != combatant.id },
                                id: \.id
                            ) { target in
                                Text(target.name).tag(Optional(target.id))
                            }
                        }
                    }
                }
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
                    .disabled(effectName.trimmingCharacters(in: .whitespaces).isEmpty ||
                              (selectedDurationType.isTargetBased && selectedTargetId == nil))
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
            durationType = .untilStartOfTheirTurn
        case .untilEndOfTheirTurn:
            durationType = .untilEndOfTheirTurn
        case .untilStartOfTargetTurn:
            guard let targetId = selectedTargetId else { return }
            durationType = .untilStartOfTargetTurn(targetID: targetId)
        case .untilEndOfTargetTurn:
            guard let targetId = selectedTargetId else { return }
            durationType = .untilEndOfTargetTurn(targetID: targetId)
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
    case untilStartOfTargetTurn
    case untilEndOfTargetTurn

    var isTargetBased: Bool {
        switch self {
        case .untilStartOfTargetTurn, .untilEndOfTargetTurn:
            return true
        default:
            return false
        }
    }
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
