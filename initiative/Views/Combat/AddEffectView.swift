import SwiftUI

/// Adds either kind of effect to a combatant: a **condition** (something wrong
/// with them) or a **cooldown** (something they can't do yet). Both are the same
/// mechanism underneath and expire through the same path — the split at the top
/// of this screen exists so that picking one narrows what's shown below it,
/// rather than presenting every field every time.
struct AddEffectView: View {
    let session: CombatSession
    let combatant: Combatant
    @Binding var isPresented: Bool

    @State private var kind: EffectKind = .condition
    @State private var effectName = ""
    @State private var selectedDurationType: DurationTypeSelection = .untilStartOfTheirTurn
    @State private var turnsCount = 1
    @State private var rollHint = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                Form {
                    Section {
                        Picker("Kind", selection: $kind) {
                            Text("Condition").tag(EffectKind.condition)
                            Text("Cooldown").tag(EffectKind.cooldown)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }

                    if kind == .condition {
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
                    } else {
                        Section("Cooldown") {
                            Menu {
                                ForEach(StandardCooldown.all) { cooldown in
                                    Button(cooldown.label) { apply(cooldown) }
                                }
                            } label: {
                                HStack {
                                    Text("Choose Cooldown")
                                    Spacer()
                                    Text(selectedCooldownLabel)
                                        .foregroundColor(Theme.textTertiary)
                                }
                            }
                        }
                    }

                    Section(kind == .condition ? "Effect Name" : "Ability Name") {
                        TextField(text: $effectName) {
                            Text(kind == .condition ? "e.g., Stunned, Poisoned" : "e.g., Breath Weapon")
                                .foregroundColor(Theme.placeholderText)
                        }
                    }

                    Section("Duration") {
                        Picker("Duration", selection: $selectedDurationType) {
                            Text("Until start of their turn").tag(DurationTypeSelection.untilStartOfTheirTurn)
                            Text("Until end of their turn").tag(DurationTypeSelection.untilEndOfTheirTurn)
                            Text("Until a roll succeeds").tag(DurationTypeSelection.untilRollSucceeds)
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()

                        if selectedDurationType == .untilRollSucceeds {
                            Picker("When", selection: $rollBoundary) {
                                Text("Start of their turn").tag(TurnBoundary.startOfTurn)
                                Text("End of their turn").tag(TurnBoundary.endOfTurn)
                            }
                            TextField(text: $rollHint) {
                                Text("What to roll — e.g. 5–6 on a d6")
                                    .foregroundColor(Theme.placeholderText)
                            }
                        } else {
                            Stepper("Turns: \(turnsCount)", value: $turnsCount, in: 1...20)
                        }
                    }

                    if selectedDurationType == .untilRollSucceeds {
                        Section {
                            // Says what the app will and won't do, at the moment
                            // the DM opts into it.
                            Text("You'll be asked for the result at that point in the turn. The app never rolls — it only remembers that you owe a roll.")
                                .font(Theme.Typography.caption)
                                .foregroundColor(Theme.textTertiary)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .listRowBackground(Theme.surfaceRaised)
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

    @State private var rollBoundary: TurnBoundary = .startOfTurn

    private var selectedCooldownLabel: String {
        guard selectedDurationType == .untilRollSucceeds, !rollHint.isEmpty else { return "Custom" }
        return rollHint
    }

    private func apply(_ cooldown: StandardCooldown) {
        effectName = cooldown.effectName
        switch cooldown.durationType {
        case .untilRollSucceeds(let boundary, let hint):
            selectedDurationType = .untilRollSucceeds
            rollBoundary = boundary
            rollHint = hint ?? ""
        case .untilStartOfTheirTurn(let turns):
            selectedDurationType = .untilStartOfTheirTurn
            turnsCount = min(20, turns)
        case .untilEndOfTheirTurn(let turns):
            selectedDurationType = .untilEndOfTheirTurn
            turnsCount = min(20, turns)
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
        case .untilRollSucceeds:
            let hint = rollHint.trimmingCharacters(in: .whitespaces)
            durationType = .untilRollSucceeds(at: rollBoundary, hint: hint.isEmpty ? nil : hint)
        }

        let effect = Effect(name: trimmedName, durationType: durationType, kind: kind)

        if let index = session.combatants.firstIndex(where: { $0.id == combatant.id }) {
            session.combatants[index].effects.append(effect)
        }
    }
}

enum DurationTypeSelection: Equatable, Hashable {
    case untilStartOfTheirTurn
    case untilEndOfTheirTurn
    case untilRollSucceeds
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
