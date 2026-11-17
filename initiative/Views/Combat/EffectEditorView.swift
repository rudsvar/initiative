import SwiftUI

/// Configures one effect's timing — a new custom one, or an existing one whose
/// default guessed wrong.
///
/// Deliberately just a few questions: how it ends (after turns, on a save, or when
/// removed) and which edge of the owner's turn it keys off. See `EffectTiming`. Every
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
    @State private var timing: EffectTiming

    init(session: CombatSession, combatantID: UUID, existing: Effect?) {
        self.session = session
        self.combatantID = combatantID
        self.existing = existing
        self.kind = existing?.kind ?? .condition
        _effectName = State(initialValue: existing?.name ?? "")
        _timing = State(initialValue: EffectTiming(existing?.durationType))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    Section(nameSectionTitle) {
                        TextField(text: $effectName) {
                            Text(namePlaceholder).foregroundColor(Theme.placeholderText)
                        }
                    }
                    .listRowBackground(Theme.surfaceRaised)

                    Section("Duration") {
                        Picker("Ends", selection: $timing.ending) {
                            Text("After turns").tag(EffectTiming.Ending.turns)
                            Text("On a save").tag(EffectTiming.Ending.save)
                            Text("When removed").tag(EffectTiming.Ending.removed)
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()

                        if timing.ending != .removed {
                            Picker("When", selection: $timing.boundary) {
                                Text("Start of their turn").tag(TurnBoundary.startOfTurn)
                                Text("End of their turn").tag(TurnBoundary.endOfTurn)
                            }
                            .pickerStyle(.segmented)
                            .labelsHidden()
                        }

                        if timing.ending == .turns {
                            Stepper("Turns: \(timing.turns)", value: $timing.turns, in: 1...20)
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
            .themedScreen()
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

    private func save() {
        let trimmedName = effectName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        if var updated = existing {
            updated.name = trimmedName
            updated.durationType = timing.durationType
            session.updateEffect(updated, on: combatantID)
        } else {
            session.addEffect(
                Effect(name: trimmedName, durationType: timing.durationType, kind: kind),
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
