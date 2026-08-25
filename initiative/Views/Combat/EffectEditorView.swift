import SwiftUI

/// Configures one effect — a new custom one, or an existing one being adjusted.
///
/// The form this replaced was the *only* way to add anything, which made "this
/// creature is stunned" cost four decisions. `EffectsView` now handles that case
/// with one tap, and this screen is what's left over: naming a custom effect, and
/// changing a duration the default guessed wrong. Both are the uncommon path,
/// which is why every field can stay on screen here without costing anything.
struct EffectEditorView: View {
    let session: CombatSession
    let combatantID: UUID
    /// nil when creating a custom effect from scratch.
    let existing: Effect?

    @Environment(\.dismiss) private var dismiss

    @State private var kind: EffectKind
    @State private var effectName: String
    @State private var selectedDurationType: DurationTypeSelection
    @State private var turnsCount: Int
    @State private var rollHint: String
    @State private var rollBoundary: TurnBoundary

    init(session: CombatSession, combatantID: UUID, existing: Effect?) {
        self.session = session
        self.combatantID = combatantID
        self.existing = existing

        let duration = existing?.durationType ?? .untilEndOfTheirTurn(remainingTurns: 1)
        _kind = State(initialValue: existing?.kind ?? .condition)
        _effectName = State(initialValue: existing?.name ?? "")

        switch duration {
        case .untilStartOfTheirTurn(let turns):
            _selectedDurationType = State(initialValue: .untilStartOfTheirTurn)
            _turnsCount = State(initialValue: min(20, max(1, turns)))
            _rollHint = State(initialValue: "")
            _rollBoundary = State(initialValue: .startOfTurn)
        case .untilEndOfTheirTurn(let turns):
            _selectedDurationType = State(initialValue: .untilEndOfTheirTurn)
            _turnsCount = State(initialValue: min(20, max(1, turns)))
            _rollHint = State(initialValue: "")
            _rollBoundary = State(initialValue: .startOfTurn)
        case .untilRollSucceeds(let boundary, let hint):
            _selectedDurationType = State(initialValue: .untilRollSucceeds)
            _turnsCount = State(initialValue: 1)
            _rollHint = State(initialValue: hint ?? "")
            _rollBoundary = State(initialValue: boundary)
        case .untilRemoved:
            _selectedDurationType = State(initialValue: .untilRemoved)
            _turnsCount = State(initialValue: 1)
            _rollHint = State(initialValue: "")
            _rollBoundary = State(initialValue: .startOfTurn)
        case .forRounds(let rounds):
            // Only reachable if a round-anchored effect is somehow opened here;
            // shown as its nearest equivalent rather than silently reset.
            _selectedDurationType = State(initialValue: .untilEndOfTheirTurn)
            _turnsCount = State(initialValue: min(20, max(1, rounds)))
            _rollHint = State(initialValue: "")
            _rollBoundary = State(initialValue: .startOfTurn)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                Form {
                    Section {
                        Picker("Kind", selection: $kind) {
                            Text("Condition").tag(EffectKind.condition)
                            Text("Cooldown").tag(EffectKind.cooldown)
                            Text("Holding").tag(EffectKind.concentration)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()
                    }
                    .listRowBackground(Theme.surfaceRaised)

                    Section(nameSectionTitle) {
                        TextField(text: $effectName) {
                            Text(namePlaceholder).foregroundColor(Theme.placeholderText)
                        }
                    }
                    .listRowBackground(Theme.surfaceRaised)

                    Section("Duration") {
                        Picker("Duration", selection: $selectedDurationType) {
                            Text("Until start of their turn").tag(DurationTypeSelection.untilStartOfTheirTurn)
                            Text("Until end of their turn").tag(DurationTypeSelection.untilEndOfTheirTurn)
                            Text("Until a roll succeeds").tag(DurationTypeSelection.untilRollSucceeds)
                            Text("Until removed").tag(DurationTypeSelection.untilRemoved)
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
                        } else if selectedDurationType != .untilRemoved {
                            Stepper("Turns: \(turnsCount)", value: $turnsCount, in: 1...20)
                        }
                    }
                    .listRowBackground(Theme.surfaceRaised)

                    if selectedDurationType == .untilRollSucceeds {
                        Section {
                            // Says what the app will and won't do, at the moment
                            // the DM opts into it.
                            Text("You'll be asked for the result at that point in the turn. The app never rolls — it only remembers that you owe a roll.")
                                .font(Theme.Typography.caption)
                                .foregroundColor(Theme.textTertiary)
                        }
                        .listRowBackground(Theme.surfaceRaised)
                    }

                    if let existing {
                        Section {
                            Button(role: .destructive) {
                                session.removeEffect(existing.id, from: combatantID)
                                dismiss()
                            } label: {
                                Label("Remove Effect", systemImage: "trash")
                            }
                        }
                        .listRowBackground(Theme.surfaceRaised)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(existing == nil ? "Custom Effect" : "Edit Effect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(existing == nil ? "Add" : "Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(effectName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private var nameSectionTitle: String {
        switch kind {
        case .condition: return "Effect Name"
        case .cooldown: return "Ability Name"
        case .concentration: return "Concentrating On"
        }
    }

    private var namePlaceholder: String {
        switch kind {
        case .condition: return "e.g., Hexed by the Duke"
        case .cooldown: return "e.g., Breath Weapon"
        case .concentration: return "e.g., Hold the Bridge"
        }
    }

    private var durationType: DurationType {
        switch selectedDurationType {
        case .untilStartOfTheirTurn:
            return .untilStartOfTheirTurn(remainingTurns: turnsCount)
        case .untilEndOfTheirTurn:
            return .untilEndOfTheirTurn(remainingTurns: turnsCount)
        case .untilRollSucceeds:
            let hint = rollHint.trimmingCharacters(in: .whitespaces)
            return .untilRollSucceeds(at: rollBoundary, hint: hint.isEmpty ? nil : hint)
        case .untilRemoved:
            return .untilRemoved
        }
    }

    private func save() {
        let trimmedName = effectName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if var updated = existing {
            updated.name = trimmedName
            updated.kind = kind
            updated.durationType = durationType
            session.updateEffect(updated, on: combatantID)
        } else {
            session.addEffect(
                Effect(name: trimmedName, durationType: durationType, kind: kind),
                to: combatantID
            )
        }
        dismiss()
    }
}

enum DurationTypeSelection: Equatable, Hashable {
    case untilStartOfTheirTurn
    case untilEndOfTheirTurn
    case untilRollSucceeds
    case untilRemoved
}

#Preview {
    let session = CombatSession()
    session.addCombatant(name: "Bog Hulk", initiative: 18)

    return EffectEditorView(session: session, combatantID: session.combatants[0].id, existing: nil)
}
