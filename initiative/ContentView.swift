import SwiftUI

struct ContentView: View {
    @State private var session = CombatSession()

    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                List {
                    InlineAddParticipantRow(session: session)

                    ForEach(session.sortedParticipants) { participant in
                        NavigationLink(destination: ParticipantDetailView(session: session, participantId: participant.id)) {
                            ParticipantRow(
                                participant: participant,
                                isCurrent: session.currentParticipant?.id == participant.id
                            )
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)

                HStack(spacing: 12) {
                    Button(action: { session.previousTurn() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Previous Turn")
                        }
                        .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(Theme.accent)
                    .disabled(!session.canGoToPreviousTurn)

                    Spacer()

                    Button(action: { session.nextTurn() }) {
                        HStack(spacing: 4) {
                            Text("Next Turn")
                            Image(systemName: "chevron.right")
                        }
                        .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(Theme.accent)
                    .disabled(session.sortedParticipants.isEmpty)
                }
                .padding(16)
                .background(Theme.background)
                .borderTop(Theme.divider)
            }
        }
    }
}

struct InlineAddParticipantRow: View {
    let session: CombatSession
    @State private var name = ""
    @State private var initiativeText = ""
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            TextField("Name", text: $name)
                .focused($nameFieldFocused)
                .foregroundColor(Theme.textPrimary)
                .submitLabel(.done)
                .onSubmit { addParticipant() }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Theme.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Theme.divider, lineWidth: 1)
                )

            TextField("Initiative", text: $initiativeText)
                .keyboardType(.numberPad)
                .foregroundColor(Theme.accent)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .frame(width: 88)
                .background(Theme.background)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Theme.divider, lineWidth: 1)
                )

            Button(action: addParticipant) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Theme.accent)
            }
            .frame(width: 44, height: 44)
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
        }
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
        .listRowBackground(Color.clear)
    }

    private func addParticipant() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let initiative = Int(initiativeText) ?? Int.random(in: 1...20)
        session.addParticipant(name: trimmedName, initiative: initiative)

        name = ""
        initiativeText = ""
        nameFieldFocused = true
    }
}

struct ParticipantRow: View {
    let participant: Participant
    let isCurrent: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(participant.name)
                        .font(.headline)
                        .foregroundColor(Theme.textPrimary)

                    HStack(spacing: 8) {
                        Text("Init \(participant.initiative)")
                            .font(.caption)
                            .foregroundColor(Theme.accent)
                            .fontWeight(.semibold)

                        if participant.reactionUsed {
                            Label("Reaction used", systemImage: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(Theme.divider)
                        } else {
                            Label("Reaction available", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(Theme.accent)
                        }
                    }
                }

                Spacer()

                if isCurrent {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Theme.accent)
                    }
                }
            }

            if !participant.effects.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(participant.effects) { effect in
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundColor(Theme.accent)
                            Text(effect.name)
                                .font(.caption)
                                .foregroundColor(Theme.textTertiary)
                        }
                    }
                }
                .padding(8)
                .background(Theme.divider.opacity(0.3))
                .cornerRadius(4)
            }
        }
        .padding(12)
        .background(isCurrent ? Theme.divider.opacity(0.3) : Color.clear)
        .cornerRadius(8)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
        .listRowBackground(Color.clear)
    }
}

#Preview {
    ContentView()
}
