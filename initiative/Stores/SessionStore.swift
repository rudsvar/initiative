import Foundation

/// A saved snapshot of a CombatSession, either a named save or the autosave slot.
struct SessionRecord: Codable, Identifiable {
    let id: UUID
    var name: String
    var savedAt: Date
    var combatants: [Combatant]
    var currentTurnIndex: Int
    /// Optional so older saved sessions (from before round tracking existed) still
    /// decode — CombatSession.load() treats a missing value as round 1.
    var roundNumber: Int?
    /// Optional for the same reason (sessions saved before the log existed) —
    /// CombatSession.load() treats a missing value as an empty log.
    var log: [LogEntry]?
    /// Optional for the same reason again — sessions saved before effects could
    /// belong to the round rather than to a creature.
    var roundEffects: [Effect]?

    init(
        id: UUID = UUID(),
        name: String,
        savedAt: Date = Date(),
        combatants: [Combatant],
        currentTurnIndex: Int,
        roundNumber: Int? = nil,
        log: [LogEntry]? = nil,
        roundEffects: [Effect]? = nil
    ) {
        self.id = id
        self.name = name
        self.savedAt = savedAt
        self.combatants = combatants
        self.currentTurnIndex = currentTurnIndex
        self.roundNumber = roundNumber
        self.log = log
        self.roundEffects = roundEffects
    }
}

/// Reads and writes combat sessions to disk as JSON, one file per session under
/// `SavedSessions/`, keyed by the session's stable id so repeated autosaves overwrite
/// the same file. There's no separate explicit-save step: every session (in-progress
/// or finished) is a regular record on disk the moment it's saved. "Resume" is just
/// "reload whichever session id was last active", tracked via UserDefaults.
@Observable
class SessionStore {
    private let files: JSONFileDirectory<SessionRecord>
    private let userDefaults: UserDefaults
    private let lastActiveIDKey = "lastActiveSessionID"

    init(baseDirectory: URL? = nil, userDefaults: UserDefaults = .standard) {
        let directory = baseDirectory
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        files = JSONFileDirectory(url: directory.appendingPathComponent("SavedSessions", isDirectory: true))
        self.userDefaults = userDefaults
    }

    func listSavedSessions() -> [SessionRecord] {
        files.readAll().sorted { $0.savedAt > $1.savedAt }
    }

    func save(_ record: SessionRecord) {
        files.write(record)
    }

    func delete(id: UUID) {
        files.remove(id: id)
        if lastActiveSessionID() == id {
            clearLastActiveSessionID()
        }
    }

    func setLastActiveSessionID(_ id: UUID) {
        userDefaults.set(id.uuidString, forKey: lastActiveIDKey)
    }

    func clearLastActiveSessionID() {
        userDefaults.removeObject(forKey: lastActiveIDKey)
    }

    func lastActiveSessionID() -> UUID? {
        guard let string = userDefaults.string(forKey: lastActiveIDKey) else { return nil }
        return UUID(uuidString: string)
    }

    /// The session to offer via "Resume" — the last active one, if it still exists on disk.
    ///
    /// Self-healing: if the pointer refers to a session that's missing or unreadable
    /// (deleted from outside the app, corrupted file, etc.), the stale pointer is
    /// cleared here rather than left dangling. Without this, a UI that checks
    /// `resumableSession() != nil` to decide whether "Resume" is enabled could show
    /// it as enabled on one call and have it silently no-op on the next — the pointer
    /// itself is the single source of truth, so it must never lie about resumability.
    func resumableSession() -> SessionRecord? {
        guard let id = lastActiveSessionID() else { return nil }
        guard let record = files.read(id: id) else {
            clearLastActiveSessionID()
            return nil
        }
        return record
    }
}
