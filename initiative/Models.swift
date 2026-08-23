import Foundation

struct Combatant: Identifiable, Codable {
    let id: UUID
    var name: String
    var initiative: Int
    var reactionUsed: Bool = false
    var effects: [Effect] = []
    var maxHP: Int?
    var currentHP: Int?

    /// Only meaningful once HP tracking is enabled (maxHP/currentHP non-nil).
    var isDead: Bool {
        guard let currentHP else { return false }
        return currentHP <= 0
    }

    init(id: UUID = UUID(), name: String, initiative: Int, maxHP: Int? = nil) {
        self.id = id
        self.name = name
        self.initiative = initiative
        self.maxHP = maxHP
        self.currentHP = maxHP
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
    var combatants: [Combatant] = []
    var currentTurnIndex: Int = 0
    var roundNumber: Int = 1

    /// Identity of this session's on-disk record — stable across autosaves so
    /// repeated saves overwrite the same file instead of piling up duplicates.
    private(set) var id = UUID()
    var name: String {
        get { _name }
        set {
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            _name = trimmed
        }
    }
    private var _name = CombatSession.defaultName()

    private var history: [(combatants: [Combatant], currentTurnIndex: Int, roundNumber: Int)] = []

    private static func defaultName() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }

    var canGoToPreviousTurn: Bool {
        !history.isEmpty
    }

    var currentCombatant: Combatant? {
        guard combatants.indices.contains(currentTurnIndex) else { return nil }
        return combatants[currentTurnIndex]
    }

    var sortedCombatants: [Combatant] {
        combatants.sorted { $0.initiative > $1.initiative }
    }

    func addCombatant(name: String, initiative: Int, maxHP: Int? = nil) {
        let combatant = Combatant(name: name, initiative: initiative, maxHP: maxHP)
        combatants.append(combatant)
        combatants.sort { $0.initiative > $1.initiative }
    }

    /// Spawns `count` copies of the same creature. Each copy always rolls its own
    /// random initiative (1...20) — a shared explicit initiative wouldn't make sense
    /// across multiple entrants, so `count > 1` ignores any single provided value.
    /// Names get a numeric suffix ("Goblin 1", "Goblin 2", ...) when count > 1.
    func addCombatants(name: String, initiative: Int?, maxHP: Int?, count: Int) {
        guard count > 0 else { return }
        for i in 1...count {
            let rolledInitiative = count > 1 ? Int.random(in: 1...20) : (initiative ?? Int.random(in: 1...20))
            let displayName = count > 1 ? "\(name) \(i)" : name
            combatants.append(Combatant(name: displayName, initiative: rolledInitiative, maxHP: maxHP))
        }
        combatants.sort { $0.initiative > $1.initiative }
    }

    func enableHPTracking(for id: UUID, maxHP: Int) {
        guard let index = combatants.firstIndex(where: { $0.id == id }), maxHP > 0 else { return }
        combatants[index].maxHP = maxHP
        combatants[index].currentHP = maxHP
    }

    func applyDamage(to id: UUID, amount: Int) {
        guard amount > 0, let index = combatants.firstIndex(where: { $0.id == id }),
              let current = combatants[index].currentHP else { return }
        combatants[index].currentHP = max(0, current - amount)
    }

    func applyHealing(to id: UUID, amount: Int) {
        guard amount > 0, let index = combatants.firstIndex(where: { $0.id == id }),
              let current = combatants[index].currentHP,
              let maxHP = combatants[index].maxHP else { return }
        combatants[index].currentHP = min(maxHP, current + amount)
    }

    func removeCombatant(id: UUID) {
        guard let index = combatants.firstIndex(where: { $0.id == id }) else { return }
        combatants.remove(at: index)
        if index < currentTurnIndex || (index == currentTurnIndex && currentTurnIndex == combatants.count) {
            currentTurnIndex = max(0, currentTurnIndex - 1)
        }
        history.removeAll()
    }

    func nextTurn() {
        guard !combatants.isEmpty else { return }

        history.append((combatants: combatants, currentTurnIndex: currentTurnIndex, roundNumber: roundNumber))

        let endingCombatantId = combatants[currentTurnIndex].id
        let wrapped = currentTurnIndex == combatants.count - 1
        currentTurnIndex = (currentTurnIndex + 1) % combatants.count
        if wrapped {
            roundNumber += 1
        }
        let startingCombatantId = combatants[currentTurnIndex].id

        removeExpiredEffects(
            turnEndingCombatantId: endingCombatantId,
            turnStartingCombatantId: startingCombatantId
        )

        combatants[currentTurnIndex].reactionUsed = false
    }

    func previousTurn() {
        guard let previous = history.popLast() else { return }
        combatants = previous.combatants
        currentTurnIndex = previous.currentTurnIndex
        roundNumber = previous.roundNumber
    }

    /// Clears all combat state and assigns a fresh identity, for starting a brand-new session.
    func reset() {
        id = UUID()
        name = CombatSession.defaultName()
        combatants = []
        currentTurnIndex = 0
        roundNumber = 1
        history = []
    }

    func makeRecord() -> SessionRecord {
        SessionRecord(id: id, name: name, combatants: combatants, currentTurnIndex: currentTurnIndex, roundNumber: roundNumber)
    }

    func load(_ record: SessionRecord) {
        id = record.id
        name = record.name
        combatants = record.combatants
        currentTurnIndex = record.currentTurnIndex
        roundNumber = record.roundNumber ?? 1
        history = []
    }

    private func removeExpiredEffects(turnEndingCombatantId: UUID, turnStartingCombatantId: UUID) {
        for i in combatants.indices {
            let ownerId = combatants[i].id
            combatants[i].effects.removeAll { effect in
                switch effect.durationType {
                case .untilEndOfTheirTurn:
                    return ownerId == turnEndingCombatantId
                case .untilEndOfTargetTurn(let targetID):
                    return targetID == turnEndingCombatantId
                case .untilStartOfTheirTurn:
                    return ownerId == turnStartingCombatantId
                case .untilStartOfTargetTurn(let targetID):
                    return targetID == turnStartingCombatantId
                }
            }
        }
    }
}
