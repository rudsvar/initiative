import SwiftUI

struct ParticipantDetailView: View {
    let session: CombatSession
    let participantId: UUID
    @Environment(\.dismiss) var dismiss
    @State private var showAddEffect = false

    var participant: Participant? {
        session.participants.first { $0.id == participantId }
    }

    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()

            if let participant = participant {
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(participant.name)
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(Theme.textPrimary)

                                        Text("Initiative \(participant.initiative)")
                                            .font(.subheadline)
                                            .foregroundColor(Theme.accent)
                                            .fontWeight(.semibold)
                                    }
                                    Spacer()
                                }
                            }
                            .padding(16)
                            .background(Theme.divider.opacity(0.2))
                            .cornerRadius(8)

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Reaction")
                                    .font(.headline)
                                    .foregroundColor(Theme.textPrimary)

                                ReactionToggleView(
                                    isUsed: participant.reactionUsed,
                                    onToggle: { toggleReaction(for: participant) }
                                )
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Active Effects")
                                        .font(.headline)
                                        .foregroundColor(Theme.textPrimary)

                                    Spacer()

                                    Button(action: { showAddEffect = true }) {
                                        Label("Add", systemImage: "plus.circle.fill")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(Theme.accent)
                                    }
                                }

                                if participant.effects.isEmpty {
                                    VStack(spacing: 8) {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 32))
                                            .foregroundColor(Theme.divider)
                                        Text("No active effects")
                                            .font(.subheadline)
                                            .foregroundColor(Theme.textTertiary)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(20)
                                } else {
                                    VStack(spacing: 8) {
                                        ForEach(participant.effects) { effect in
                                            EffectRowView(
                                                effect: effect,
                                                onRemove: { removeEffect(effect, from: participant) }
                                            )
                                        }
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
        }
        .navigationTitle("Participant")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddEffect) {
            if let participant = participant {
                AddEffectView(
                    session: session,
                    participant: participant,
                    isPresented: $showAddEffect
                )
            }
        }
    }

    private func toggleReaction(for participant: Participant) {
        if let index = session.participants.firstIndex(where: { $0.id == participant.id }) {
            session.participants[index].reactionUsed.toggle()
        }
    }

    private func removeEffect(_ effect: Effect, from participant: Participant) {
        if let pIndex = session.participants.firstIndex(where: { $0.id == participant.id }) {
            session.participants[pIndex].effects.removeAll { $0.id == effect.id }
        }
    }
}

struct ReactionToggleView: View {
    let isUsed: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                Image(systemName: isUsed ? "xmark.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Theme.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text(isUsed ? "Reaction Used" : "Reaction Available")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Theme.textPrimary)

                    Text(isUsed ? "Mark as available" : "Mark as used")
                        .font(.caption)
                        .foregroundColor(Theme.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Theme.divider)
            }
            .padding(12)
            .background(isUsed ? Theme.divider.opacity(0.2) : Theme.accent.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct EffectRowView: View {
    let effect: Effect
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(effect.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Theme.textPrimary)

                Text(effect.durationType.description)
                    .font(.caption)
                    .foregroundColor(Theme.textTertiary)
            }

            Spacer()

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(Theme.divider)
            }
        }
        .padding(12)
        .background(Theme.divider.opacity(0.2))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationStack {
        ParticipantDetailView(
            session: {
                let session = CombatSession()
                session.addParticipant(name: "Goblin", initiative: 15)
                return session
            }(),
            participantId: UUID()
        )
    }
}
