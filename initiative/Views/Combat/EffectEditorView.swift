import SwiftUI

/// Configures one effect's timing — a new custom one, or an existing one whose
/// default guessed wrong.
///
/// Deliberately just two questions: which edge of the owner's turn it keys off,
/// and whether it clears on a roll or after a fixed number of turns. Every
/// standard condition applies with a sensible default in one tap from the grid
/// in `CombatantDetailView`; this screen only exists for the minority of cases
/// that need adjusting, which is why it can afford to be this small.
struct EffectEditorView: View {
    let session: CombatSession
    let combatantID: UUID
    /// nil when creating a custom effect from scratch.
    let existing: Effect?
    let kind: EffectKind

    @Environment(\.dismiss) private var dismiss

    @State private var effectName: String
    @State private var boundary: TurnBoundary
    @State private var requiresSave: Bool
    @State private var turnsCount: Int
    /// Carried through unedited rather than shown — a cooldown's "5–6 on a d6"
    /// would otherwise be silently lost the moment someone just tweaks the
    /// boundary. Only ever set by code that already knows what to roll.
    @State private var rollHint: String

    init(session: CombatSession, combatantID: UUID, existing: Effect?) {
        self.session = session
        self.combatantID = combatantID
        self.existing = existing
        self.kind = existing?.kind ?? .condition

        _effectName = State(initialValue: existing?.name ?? "")

        switch existing?.durationType {
        case .untilStartOfTheirTurn(let turns):
            _boundary = State(initialValue: .startOfTurn)
            _requiresSave = State(initialValue: false)
            _turnsCount = State(initialValue: min(20, max(1, turns)))
            _rollHint = State(initialValue: "")
        case .untilEndOfTheirTurn(let turns):
            _boundary = State(initialValue: .endOfTurn)
            _requiresSave = State(initialValue: false)
            _turnsCount = State(initialValue: min(20, max(1, turns)))
            _rollHint = State(initialValue: "")
        case .untilRollSucceeds(let boundary, let hint):
            _boundary = State(initialValue: boundary)
            _requiresSave = State(initialValue: true)
            _turnsCount = State(initialValue: 1)
            _rollHint = State(initialValue: hint ?? "")
        case .untilRemoved, .forRounds, .none:
            // "Until removed" isn't representable here on purpose — it's cleared
            // by tapping the chip off again, not by a duration setting. Opening
            // this screen on one of those and saving moves it onto the
            // save/turns model, which is the one thing this screen can express.
            _boundary = State(initialValue: .startOfTurn)
            _requiresSave = State(initialValue: true)
            _turnsCount = State(initialValue: 1)
            _rollHint = State(initialValue: "")
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                Form {
                    Section(nameSectionTitle) {
                        TextField(text: $effectName) {
                            Text(namePlaceholder).foregroundColor(Theme.placeholderText)
                        }
                    }
                    .listRowBackground(Theme.surfaceRaised)

                    Section("Duration") {
                        Picker("When", selection: $boundary) {
                            Text("Start of their turn").tag(TurnBoundary.startOfTurn)
                            Text("End of their turn").tag(TurnBoundary.endOfTurn)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()

                        Toggle("Requires a save", isOn: $requiresSave)

                        if !requiresSave {
                            Stepper("Turns: \(turnsCount)", value: $turnsCount, in: 1...20)
                        }
                    }
                    .listRowBackground(Theme.surfaceRaised)

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
            .navigationTitle(existing == nil ? "Custom Effect" : "Configure Effect")
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
        kind == .cooldown ? "Ability Name" : "Effect Name"
    }

    private var namePlaceholder: String {
        kind == .cooldown ? "e.g., Breath Weapon" : "e.g., Hexed by the Duke"
    }

    private var durationType: DurationType {
        if requiresSave {
            let hint = rollHint.trimmingCharacters(in: .whitespaces)
            return .untilRollSucceeds(at: boundary, hint: hint.isEmpty ? nil : hint)
        }
        return boundary == .startOfTurn
            ? .untilStartOfTheirTurn(remainingTurns: turnsCount)
            : .untilEndOfTheirTurn(remainingTurns: turnsCount)
    }

    private func save() {
        let trimmedName = effectName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if var updated = existing {
            updated.name = trimmedName
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

#Preview {
    let session = CombatSession()
    session.addCombatant(name: "Bog Hulk", initiative: 18)

    return EffectEditorView(session: session, combatantID: session.combatants[0].id, existing: nil)
}
