import SwiftUI

struct ContentView: View {
    @State private var session = CombatSession()
    @State private var showAddParticipant = false

    var body: some View {
        ZStack {
            Color(red: 0.96, green: 0.94, blue: 0.93)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button(action: { showAddParticipant = true }) {
                        Label("Add", systemImage: "plus.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color(red: 0.65, green: 0.30, blue: 0.24))
                    }
                    .padding(.leading, 16)

                    Spacer()
                }
                .frame(height: 44)
                .background(Color(red: 0.96, green: 0.94, blue: 0.93))
                .borderBottom(Color(red: 0.83, green: 0.76, blue: 0.72))

                if session.sortedParticipants.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2")
                            .font(.system(size: 48))
                            .foregroundColor(Color(red: 0.83, green: 0.76, blue: 0.72))
                        Text("No participants yet")
                            .font(.headline)
                            .foregroundColor(Color(red: 0.43, green: 0.35, blue: 0.32))
                        Text("Add participants to begin tracking initiative")
                            .font(.subheadline)
                            .foregroundColor(Color(red: 0.60, green: 0.50, blue: 0.45))
                    }
                    .frame(maxHeight: .infinity)
                    .frame(maxWidth: .infinity)
                } else {
                    List {
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
                }

                HStack(spacing: 12) {
                    Button(action: { session.nextTurn() }) {
                        Label("Back", systemImage: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(Color(red: 0.65, green: 0.30, blue: 0.24))
                    .disabled(session.sortedParticipants.isEmpty)

                    Spacer()

                    Button(action: { session.nextTurn() }) {
                        Label("Next Turn", systemImage: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(Color(red: 0.65, green: 0.30, blue: 0.24))
                    .disabled(session.sortedParticipants.isEmpty)
                }
                .padding(16)
                .background(Color(red: 0.96, green: 0.94, blue: 0.93))
                .borderTop(Color(red: 0.83, green: 0.76, blue: 0.72))
            }
        }
        .sheet(isPresented: $showAddParticipant) {
            AddParticipantView(session: session, isPresented: $showAddParticipant)
        }
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
                        .foregroundColor(Color(red: 0.17, green: 0.15, blue: 0.13))

                    HStack(spacing: 8) {
                        Text("Init \(participant.initiative)")
                            .font(.caption)
                            .foregroundColor(Color(red: 0.65, green: 0.30, blue: 0.24))
                            .fontWeight(.semibold)

                        if participant.reactionUsed {
                            Label("Reaction used", systemImage: "xmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(Color(red: 0.83, green: 0.76, blue: 0.72))
                        } else {
                            Label("Reaction available", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(Color(red: 0.65, green: 0.30, blue: 0.24))
                        }
                    }
                }

                Spacer()

                if isCurrent {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(red: 0.65, green: 0.30, blue: 0.24))
                    }
                }
            }

            if !participant.effects.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(participant.effects) { effect in
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundColor(Color(red: 0.65, green: 0.30, blue: 0.24))
                            Text(effect.name)
                                .font(.caption)
                                .foregroundColor(Color(red: 0.60, green: 0.50, blue: 0.45))
                        }
                    }
                }
                .padding(8)
                .background(Color(red: 0.83, green: 0.76, blue: 0.72).opacity(0.3))
                .cornerRadius(4)
            }
        }
        .padding(12)
        .background(isCurrent ? Color(red: 0.83, green: 0.76, blue: 0.72).opacity(0.3) : Color.clear)
        .cornerRadius(8)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8))
        .listRowBackground(Color.clear)
    }
}

struct AddParticipantView: View {
    let session: CombatSession
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var initiativeText = ""
    @State private var useRandomInitiative = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.96, green: 0.94, blue: 0.93)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Participant Name")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.43, green: 0.35, blue: 0.32))
                        TextField("Enter name", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal, 4)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Initiative")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.43, green: 0.35, blue: 0.32))

                        Toggle(isOn: $useRandomInitiative) {
                            Text("Random (1-20)")
                                .foregroundColor(Color(red: 0.43, green: 0.35, blue: 0.32))
                        }
                        .tint(Color(red: 0.65, green: 0.30, blue: 0.24))

                        if !useRandomInitiative {
                            TextField("Enter initiative", text: $initiativeText)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .padding(.horizontal, 4)
                        }
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Add Participant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(Color(red: 0.65, green: 0.30, blue: 0.24))
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addParticipant()
                        isPresented = false
                    }
                    .foregroundColor(Color(red: 0.65, green: 0.30, blue: 0.24))
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func addParticipant() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let initiative: Int
        if useRandomInitiative {
            initiative = Int.random(in: 1...20)
        } else {
            initiative = Int(initiativeText) ?? 10
        }

        session.addParticipant(name: trimmedName, initiative: initiative)
    }
}

#Preview {
    ContentView()
}
