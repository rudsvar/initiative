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

struct LogEntry: Identifiable, Codable {
    let id: UUID
    var text: String
    var timestamp: Date

    init(id: UUID = UUID(), text: String, timestamp: Date = Date()) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
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
    private(set) var log: [LogEntry] = []

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

    private var history: [(combatants: [Combatant], currentTurnIndex: Int, roundNumber: Int, logCount: Int)] = []

    private func appendLog(_ text: String) {
        log.append(LogEntry(text: text))
    }

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

    /// `initiative: nil` rolls 1...20 plus `initiativeBonus` (a flat modifier, e.g. from
    /// a creature preset). An explicit `initiative` value is used exactly as given —
    /// the bonus only applies to random rolls, never on top of a deliberate value.
    func addCombatant(name: String, initiative: Int? = nil, maxHP: Int? = nil, initiativeBonus: Int = 0) {
        let resolvedInitiative = initiative ?? (Int.random(in: 1...20) + initiativeBonus)
        let combatant = Combatant(name: name, initiative: resolvedInitiative, maxHP: maxHP)
        combatants.append(combatant)
        combatants.sort { $0.initiative > $1.initiative }
        appendLog("\(name) added to combat (initiative \(resolvedInitiative))")
    }

    /// Spawns `count` copies of the same creature. Each copy always rolls its own
    /// random initiative (1...20 + initiativeBonus) — a shared explicit initiative
    /// wouldn't make sense across multiple entrants, so `count > 1` ignores any
    /// single provided value. Names get a numeric suffix ("Goblin 1", "Goblin 2", ...)
    /// when count > 1.
    func addCombatants(name: String, initiative: Int?, maxHP: Int?, count: Int, initiativeBonus: Int = 0) {
        guard count > 0 else { return }
        for i in 1...count {
            let rolledInitiative = count > 1
                ? Int.random(in: 1...20) + initiativeBonus
                : (initiative ?? (Int.random(in: 1...20) + initiativeBonus))
            let displayName = count > 1 ? "\(name) \(i)" : name
            combatants.append(Combatant(name: displayName, initiative: rolledInitiative, maxHP: maxHP))
        }
        combatants.sort { $0.initiative > $1.initiative }
        appendLog(count > 1 ? "\(count)x \(name) added to combat" : "\(name) added to combat")
    }

    func enableHPTracking(for id: UUID, maxHP: Int) {
        guard let index = combatants.firstIndex(where: { $0.id == id }), maxHP > 0 else { return }
        combatants[index].maxHP = maxHP
        combatants[index].currentHP = maxHP
        appendLog("\(combatants[index].name) started tracking HP (\(maxHP)/\(maxHP))")
    }

    func applyDamage(to id: UUID, amount: Int) {
        guard amount > 0, let index = combatants.firstIndex(where: { $0.id == id }),
              let current = combatants[index].currentHP else { return }
        combatants[index].currentHP = max(0, current - amount)
        appendLog("\(combatants[index].name) took \(amount) damage (\(combatants[index].currentHP!)/\(combatants[index].maxHP!) HP)")
        if combatants[index].isDead {
            appendLog("\(combatants[index].name) died")
        }
    }

    func applyHealing(to id: UUID, amount: Int) {
        guard amount > 0, let index = combatants.firstIndex(where: { $0.id == id }),
              let current = combatants[index].currentHP,
              let maxHP = combatants[index].maxHP else { return }
        combatants[index].currentHP = min(maxHP, current + amount)
        appendLog("\(combatants[index].name) healed \(amount) HP (\(combatants[index].currentHP!)/\(maxHP) HP)")
    }

    /// Raises both max and current HP by `amount` (a temporary buff, leveling up,
    /// etc. — the kind of boost that also tops you up, not just a higher ceiling).
    func increaseMaxHP(for id: UUID, amount: Int) {
        guard amount > 0, let index = combatants.firstIndex(where: { $0.id == id }),
              let maxHP = combatants[index].maxHP,
              let current = combatants[index].currentHP else { return }
        combatants[index].maxHP = maxHP + amount
        combatants[index].currentHP = current + amount
        appendLog("\(combatants[index].name)'s max HP increased by \(amount) (\(combatants[index].currentHP!)/\(combatants[index].maxHP!) HP)")
    }

    func removeCombatant(id: UUID) {
        guard let index = combatants.firstIndex(where: { $0.id == id }) else { return }
        let name = combatants[index].name
        combatants.remove(at: index)
        if index < currentTurnIndex || (index == currentTurnIndex && currentTurnIndex == combatants.count) {
            currentTurnIndex = max(0, currentTurnIndex - 1)
        }
        history.removeAll()
        appendLog("\(name) removed from combat")
    }

    func nextTurn() {
        guard !combatants.isEmpty else { return }

        history.append((combatants: combatants, currentTurnIndex: currentTurnIndex, roundNumber: roundNumber, logCount: log.count))

        let endingCombatantId = combatants[currentTurnIndex].id
        let wrapped = currentTurnIndex == combatants.count - 1
        currentTurnIndex = (currentTurnIndex + 1) % combatants.count
        if wrapped {
            roundNumber += 1
            appendLog("Round \(roundNumber) began")
        }
        let startingCombatantId = combatants[currentTurnIndex].id

        removeExpiredEffects(
            turnEndingCombatantId: endingCombatantId,
            turnStartingCombatantId: startingCombatantId
        )

        combatants[currentTurnIndex].reactionUsed = false
        appendLog("\(combatants[currentTurnIndex].name)'s turn")
    }

    /// Reverts combatants/turn index/round number to the pre-nextTurn() snapshot,
    /// and truncates the log back to its length at that same point — anything
    /// logged during the turn being undone (damage, heals, etc.) is removed too,
    /// so the log never shows events for a turn that's no longer considered to
    /// have happened.
    func previousTurn() {
        guard let previous = history.popLast() else { return }
        combatants = previous.combatants
        currentTurnIndex = previous.currentTurnIndex
        roundNumber = previous.roundNumber
        log = Array(log.prefix(previous.logCount))
    }

    /// Clears all combat state and assigns a fresh identity, for starting a brand-new session.
    func reset() {
        id = UUID()
        name = CombatSession.defaultName()
        combatants = []
        currentTurnIndex = 0
        roundNumber = 1
        log = []
        history = []
    }

    func makeRecord() -> SessionRecord {
        SessionRecord(id: id, name: name, combatants: combatants, currentTurnIndex: currentTurnIndex, roundNumber: roundNumber, log: log)
    }

    func load(_ record: SessionRecord) {
        id = record.id
        name = record.name
        combatants = record.combatants
        currentTurnIndex = record.currentTurnIndex
        roundNumber = record.roundNumber ?? 1
        log = record.log ?? []
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
