import SwiftUI

struct AddEffectView: View {
    let session: CombatSession
    let participant: Participant
    @Binding var isPresented: Bool
    @State private var effectName = ""
    @State private var selectedDurationType: DurationTypeSelection = .untilStartOfTheirTurn
    @State private var selectedTargetId: UUID?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.96, green: 0.94, blue: 0.93)
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Effect Name")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.43, green: 0.35, blue: 0.32))
                        TextField("e.g., Stunned, Poisoned", text: $effectName)
                            .textFieldStyle(.roundedBorder)
                            .padding(.horizontal, 4)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Duration")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(red: 0.43, green: 0.35, blue: 0.32))

                        VStack(spacing: 8) {
                            DurationTypeButton(
                                title: "Until start of their next turn",
                                isSelected: selectedDurationType == .untilStartOfTheirTurn,
                                action: {
                                    selectedDurationType = .untilStartOfTheirTurn
                                    selectedTargetId = nil
                                }
                            )

                            DurationTypeButton(
                                title: "Until end of their next turn",
                                isSelected: selectedDurationType == .untilEndOfTheirTurn,
                                action: {
                                    selectedDurationType = .untilEndOfTheirTurn
                                    selectedTargetId = nil
                                }
                            )

                            DurationTypeButton(
                                title: "Until start of target's next turn",
                                isSelected: selectedDurationType == .untilStartOfTargetTurn,
                                action: {
                                    selectedDurationType = .untilStartOfTargetTurn
                                    if selectedTargetId == nil {
                                        selectedTargetId = session.participants
                                            .first(where: { $0.id != participant.id })?
                                            .id
                                    }
                                }
                            )

                            DurationTypeButton(
                                title: "Until end of target's next turn",
                                isSelected: selectedDurationType == .untilEndOfTargetTurn,
                                action: {
                                    selectedDurationType = .untilEndOfTargetTurn
                                    if selectedTargetId == nil {
                                        selectedTargetId = session.participants
                                            .first(where: { $0.id != participant.id })?
                                            .id
                                    }
                                }
                            )
                        }
                    }

                    if selectedDurationType.isTargetBased {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Target")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(Color(red: 0.43, green: 0.35, blue: 0.32))

                            Picker("Select target", selection: $selectedTargetId) {
                                ForEach(
                                    session.participants.filter { $0.id != participant.id },
                                    id: \.id
                                ) { target in
                                    Text(target.name).tag(Optional(target.id))
                                }
                            }
                            .pickerStyle(.menu)
                            .foregroundColor(Color(red: 0.17, green: 0.15, blue: 0.13))
                        }
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Add Effect")
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
                        addEffect()
                        isPresented = false
                    }
                    .foregroundColor(Color(red: 0.65, green: 0.30, blue: 0.24))
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

        if let index = session.participants.firstIndex(where: { $0.id == participant.id }) {
            session.participants[index].effects.append(effect)
        }
    }
}

struct DurationTypeButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(Color(red: 0.65, green: 0.30, blue: 0.24))

                Text(title)
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.17, green: 0.15, blue: 0.13))

                Spacer()
            }
            .padding(12)
            .background(isSelected ? Color(red: 0.65, green: 0.30, blue: 0.24).opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
    }
}

enum DurationTypeSelection: Equatable {
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
    session.addParticipant(name: "Player", initiative: 20)
    session.addParticipant(name: "Enemy", initiative: 15)

    return AddEffectView(
        session: session,
        participant: session.participants.first!,
        isPresented: .constant(true)
    )
}
