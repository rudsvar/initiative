import Foundation

struct Participant: Identifiable {
    let id: UUID
    var name: String
    var initiative: Int
    var reactionUsed: Bool = false
    var effects: [Effect] = []

    init(id: UUID = UUID(), name: String, initiative: Int) {
        self.id = id
        self.name = name
        self.initiative = initiative
    }
}

struct Effect: Identifiable {
    let id: UUID
    var name: String
    var durationType: DurationType

    init(id: UUID = UUID(), name: String, durationType: DurationType) {
        self.id = id
        self.name = name
        self.durationType = durationType
    }
}

enum DurationType: Equatable {
    case untilStartOfTheirTurn
    case untilEndOfTheirTurn
    case untilStartOfTargetTurn(targetID: UUID)
    case untilEndOfTargetTurn(targetID: UUID)

    var description: String {
        switch self {
        case .untilStartOfTheirTurn:
            return "Until start of their next turn"
        case .untilEndOfTheirTurn:
            return "Until end of their next turn"
        case .untilStartOfTargetTurn:
            return "Until start of target's next turn"
        case .untilEndOfTargetTurn:
            return "Until end of target's next turn"
        }
    }
}

@Observable
class CombatSession {
    var participants: [Participant] = []
    var currentTurnIndex: Int = 0

    var currentParticipant: Participant? {
        guard participants.indices.contains(currentTurnIndex) else { return nil }
        return participants[currentTurnIndex]
    }

    var sortedParticipants: [Participant] {
        participants.sorted { $0.initiative > $1.initiative }
    }

    func addParticipant(name: String, initiative: Int) {
        let participant = Participant(name: name, initiative: initiative)
        participants.append(participant)
        participants.sort { $0.initiative > $1.initiative }
    }

    func nextTurn() {
        guard !participants.isEmpty else { return }

        let endingParticipantId = participants[currentTurnIndex].id
        currentTurnIndex = (currentTurnIndex + 1) % participants.count
        let startingParticipantId = participants[currentTurnIndex].id

        removeExpiredEffects(
            turnEndingParticipantId: endingParticipantId,
            turnStartingParticipantId: startingParticipantId
        )

        participants[currentTurnIndex].reactionUsed = false
    }

    private func removeExpiredEffects(turnEndingParticipantId: UUID, turnStartingParticipantId: UUID) {
        for i in participants.indices {
            let ownerId = participants[i].id
            participants[i].effects.removeAll { effect in
                switch effect.durationType {
                case .untilEndOfTheirTurn:
                    return ownerId == turnEndingParticipantId
                case .untilEndOfTargetTurn(let targetID):
                    return targetID == turnEndingParticipantId
                case .untilStartOfTheirTurn:
                    return ownerId == turnStartingParticipantId
                case .untilStartOfTargetTurn(let targetID):
                    return targetID == turnStartingParticipantId
                }
            }
        }
    }
}
