import SwiftUI

/// Effects belonging to the fight rather than to any creature in it.
///
/// A separate screen from the combatant's effects (`EffectEditorView`) rather than a mode of it, because almost
/// nothing carries over: there are no conditions to pick from (a bridge isn't
/// Frightened), no concentration, and the durations available are different —
/// a round-anchored effect counts rounds, not somebody's turns. Sharing the
/// screen would have meant most of it being conditionally hidden.
struct RoundEffectsView: View {
    let session: CombatSession
    @Binding var isPresented: Bool

    @State private var name = ""
    @State private var duration: RoundDurationSelection = .rounds
    @State private var rounds = 1
    @State private var rollHint = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                Form {
                    if !session.roundEffects.isEmpty {
                        Section {
                            ForEach(session.roundEffects) { effect in
                                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                                    Text(effect.name)
                                        .font(Theme.Typography.bodyEmphasis)
                                        .foregroundColor(Theme.textPrimary)
                                    Text(effect.durationType.roundDescription)
                                        .font(Theme.Typography.caption)
                                        .foregroundColor(Theme.textTertiary)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        session.removeRoundEffect(effect.id)
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                    }
                                }
                            }
                        } header: {
                            Text("In play").sectionLabel()
                        }
                        .listRowBackground(Theme.surfaceRaised)
                    }

                    Section("Name") {
                        TextField(text: $name) {
                            Text("e.g., The bridge is burning")
                                .foregroundColor(Theme.placeholderText)
                        }
                    }
                    .listRowBackground(Theme.surfaceRaised)

                    Section("Duration") {
                        Picker("Duration", selection: $duration) {
                            Text("For a number of rounds").tag(RoundDurationSelection.rounds)
                            Text("Until a roll succeeds").tag(RoundDurationSelection.roll)
                            Text("Until removed").tag(RoundDurationSelection.removed)
                        }
                        .pickerStyle(.inline)
                        .labelsHidden()

                        switch duration {
                        case .rounds:
                            Stepper("Rounds: \(rounds)", value: $rounds, in: 1...20)
                        case .roll:
                            // No example roll here on purpose — what's rolled
                            // and what counts as a success depends entirely
                            // on the rules in play and the specific ability,
                            // neither of which this app knows or assumes.
                            // The DM fills in whatever their own rules call for.
                            TextField(text: $rollHint) {
                                Text("What to roll (optional)")
                                    .foregroundColor(Theme.placeholderText)
                            }
                        case .removed:
                            EmptyView()
                        }
                    }
                    .listRowBackground(Theme.surfaceRaised)

                    Section {
                        Text(footnote)
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.textTertiary)
                    }
                    .listRowBackground(Theme.surfaceRaised)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Round Effects")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { add() }
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private var footnote: String {
        switch duration {
        case .rounds: return "Counts down at the top of each round, not on anyone's turn."
        case .roll: return "You'll be asked for the result when the round turns over."
        case .removed: return "Stays until you remove it."
        }
    }

    private func add() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        let durationType: DurationType
        switch duration {
        case .rounds:
            durationType = .forRounds(remaining: rounds)
        case .roll:
            let hint = rollHint.trimmingCharacters(in: .whitespaces)
            durationType = .untilRollSucceeds(at: .startOfTurn, hint: hint.isEmpty ? nil : hint)
        case .removed:
            durationType = .untilRemoved
        }

        session.addRoundEffect(Effect(name: trimmed, durationType: durationType))
        name = ""
        rollHint = ""
        rounds = 1
    }
}

enum RoundDurationSelection: Hashable {
    case rounds
    case roll
    case removed
}

#Preview {
    let session = CombatSession()
    session.addRoundEffect(Effect(name: "The bridge is burning", durationType: .forRounds(remaining: 3)))

    return RoundEffectsView(session: session, isPresented: .constant(true))
}
