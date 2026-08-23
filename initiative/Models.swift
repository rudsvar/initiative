import Foundation

struct Participant: Identifiable, Codable {
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

struct Effect: Identifiable, Codable {
    let id: UUID
    var name: String
    var durationType: DurationType

    init(id: UUID = UUID(), name: String, durationType: DurationType) {
        self.id = id
        self.name = name
        self.durationType = durationType
    }
}

enum DurationType: Equatable, Codable {
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

    private enum Kind: String, Codable {
        case untilStartOfTheirTurn, untilEndOfTheirTurn, untilStartOfTargetTurn, untilEndOfTargetTurn
    }

    private enum CodingKeys: String, CodingKey {
        case kind, targetID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Kind.self, forKey: .kind) {
        case .untilStartOfTheirTurn:
            self = .untilStartOfTheirTurn
        case .untilEndOfTheirTurn:
            self = .untilEndOfTheirTurn
        case .untilStartOfTargetTurn:
            self = .untilStartOfTargetTurn(targetID: try container.decode(UUID.self, forKey: .targetID))
        case .untilEndOfTargetTurn:
            self = .untilEndOfTargetTurn(targetID: try container.decode(UUID.self, forKey: .targetID))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .untilStartOfTheirTurn:
            try container.encode(Kind.untilStartOfTheirTurn, forKey: .kind)
        case .untilEndOfTheirTurn:
            try container.encode(Kind.untilEndOfTheirTurn, forKey: .kind)
        case .untilStartOfTargetTurn(let targetID):
            try container.encode(Kind.untilStartOfTargetTurn, forKey: .kind)
            try container.encode(targetID, forKey: .targetID)
        case .untilEndOfTargetTurn(let targetID):
            try container.encode(Kind.untilEndOfTargetTurn, forKey: .kind)
            try container.encode(targetID, forKey: .targetID)
        }
    }
}

@Observable
class CombatSession {
    var participants: [Participant] = []
    var currentTurnIndex: Int = 0

    /// Identity of this session's on-disk record — stable across autosaves so
    /// repeated saves overwrite the same file instead of piling up duplicates.
    private(set) var id = UUID()
    private(set) var name = CombatSession.defaultName()

    private var history: [(participants: [Participant], currentTurnIndex: Int)] = []

    private static func defaultName() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "Session — \(formatter.string(from: Date()))"
    }

    var canGoToPreviousTurn: Bool {
        !history.isEmpty
    }

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

        history.append((participants: participants, currentTurnIndex: currentTurnIndex))

        let endingParticipantId = participants[currentTurnIndex].id
        currentTurnIndex = (currentTurnIndex + 1) % participants.count
        let startingParticipantId = participants[currentTurnIndex].id

        removeExpiredEffects(
            turnEndingParticipantId: endingParticipantId,
            turnStartingParticipantId: startingParticipantId
        )

        participants[currentTurnIndex].reactionUsed = false
    }

    func previousTurn() {
        guard let previous = history.popLast() else { return }
        participants = previous.participants
        currentTurnIndex = previous.currentTurnIndex
    }

    /// Clears all combat state and assigns a fresh identity, for starting a brand-new session.
    func reset() {
        id = UUID()
        name = CombatSession.defaultName()
        participants = []
        currentTurnIndex = 0
        history = []
    }

    func makeRecord() -> SessionRecord {
        SessionRecord(id: id, name: name, participants: participants, currentTurnIndex: currentTurnIndex)
    }

    func load(_ record: SessionRecord) {
        id = record.id
        name = record.name
        participants = record.participants
        currentTurnIndex = record.currentTurnIndex
        history = []
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
