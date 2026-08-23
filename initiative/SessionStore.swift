import Foundation

/// A saved snapshot of a CombatSession, either a named save or the autosave slot.
struct SessionRecord: Codable, Identifiable {
    let id: UUID
    var name: String
    var savedAt: Date
    var combatants: [Combatant]
    var currentTurnIndex: Int

    init(
        id: UUID = UUID(),
        name: String,
        savedAt: Date = Date(),
        combatants: [Combatant],
        currentTurnIndex: Int
    ) {
        self.id = id
        self.name = name
        self.savedAt = savedAt
        self.combatants = combatants
        self.currentTurnIndex = currentTurnIndex
    }
}

/// Reads and writes combat sessions to disk as JSON, one file per session under
/// `SavedSessions/`, keyed by the session's stable id so repeated autosaves overwrite
/// the same file. There's no separate explicit-save step: every session (in-progress
/// or finished) is a regular record on disk the moment it's saved. "Resume" is just
/// "reload whichever session id was last active", tracked via UserDefaults.
@Observable
class SessionStore {
    private let fileManager = FileManager.default
    private let baseDirectory: URL
    private let userDefaults: UserDefaults
    private let lastActiveIDKey = "lastActiveSessionID"

    init(baseDirectory: URL? = nil, userDefaults: UserDefaults = .standard) {
        let directory = baseDirectory
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.baseDirectory = directory
        self.userDefaults = userDefaults
    }

    private var sessionsDirectory: URL {
        let dir = baseDirectory.appendingPathComponent("SavedSessions", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    func listSavedSessions() -> [SessionRecord] {
        guard let files = try? fileManager.contentsOfDirectory(at: sessionsDirectory, includingPropertiesForKeys: nil) else {
            return []
        }
        return files
            .compactMap { url -> SessionRecord? in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? JSONDecoder().decode(SessionRecord.self, from: data)
            }
            .sorted { $0.savedAt > $1.savedAt }
    }

    func save(_ record: SessionRecord) {
        let url = sessionsDirectory.appendingPathComponent("\(record.id.uuidString).json")
        guard let data = try? JSONEncoder().encode(record) else { return }
        try? data.write(to: url)
    }

    func delete(id: UUID) {
        let url = sessionsDirectory.appendingPathComponent("\(id.uuidString).json")
        try? fileManager.removeItem(at: url)
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
        let url = sessionsDirectory.appendingPathComponent("\(id.uuidString).json")
        guard let data = try? Data(contentsOf: url),
              let record = try? JSONDecoder().decode(SessionRecord.self, from: data) else {
            clearLastActiveSessionID()
            return nil
        }
        return record
    }
}
