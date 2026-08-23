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
        if participants.isEmpty { return }

        // Reset reaction for current participant
        if currentTurnIndex < participants.count {
            participants[currentTurnIndex].reactionUsed = false

            // Remove expired effects
            removeExpiredEffects(for: currentTurnIndex, at: .start)
        }

        // Advance to next participant
        currentTurnIndex = (currentTurnIndex + 1) % participants.count
    }

    private func removeExpiredEffects(for participantIndex: Int, at timing: EffectTiming) {
        guard participantIndex < participants.count else { return }

        participants[participantIndex].effects.removeAll { effect in
            shouldRemoveEffect(effect, at: timing, forParticipant: participantIndex)
        }
    }

    private func shouldRemoveEffect(_ effect: Effect, at timing: EffectTiming, forParticipant participantIndex: Int) -> Bool {
        switch (effect.durationType, timing) {
        case (.untilStartOfTheirTurn, .start):
            return true
        case (.untilEndOfTheirTurn, .end):
            return true
        case (.untilStartOfTargetTurn(let targetID), .start):
            return findParticipantIndex(by: targetID) == participantIndex
        case (.untilEndOfTargetTurn(let targetID), .end):
            return findParticipantIndex(by: targetID) == participantIndex
        default:
            return false
        }
    }

    private func findParticipantIndex(by id: UUID) -> Int? {
        participants.firstIndex { $0.id == id }
    }
}

enum EffectTiming {
    case start
    case end
}
