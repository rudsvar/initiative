import Foundation

/// A saved snapshot of a CombatSession, either a named save or the autosave slot.
struct SessionRecord: Codable, Identifiable {
    let id: UUID
    var name: String
    var savedAt: Date
    var participants: [Participant]
    var currentTurnIndex: Int

    init(
        id: UUID = UUID(),
        name: String,
        savedAt: Date = Date(),
        participants: [Participant],
        currentTurnIndex: Int
    ) {
        self.id = id
        self.name = name
        self.savedAt = savedAt
        self.participants = participants
        self.currentTurnIndex = currentTurnIndex
    }
}

/// Reads and writes combat sessions to disk as JSON. Named saves live one-file-per-session
/// under `SavedSessions/`; the autosave slot is a single well-known file used to support
/// "Resume" without requiring an explicit save.
@Observable
class SessionStore {
    private let fileManager = FileManager.default
    private let baseDirectory: URL

    init(baseDirectory: URL? = nil) {
        let directory = baseDirectory
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.baseDirectory = directory
    }

    private var sessionsDirectory: URL {
        let dir = baseDirectory.appendingPathComponent("SavedSessions", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private var autosaveURL: URL {
        baseDirectory.appendingPathComponent("autosave.json")
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
    }

    func saveAutosave(_ record: SessionRecord) {
        guard let data = try? JSONEncoder().encode(record) else { return }
        try? data.write(to: autosaveURL)
    }

    func loadAutosave() -> SessionRecord? {
        guard let data = try? Data(contentsOf: autosaveURL) else { return nil }
        return try? JSONDecoder().decode(SessionRecord.self, from: data)
    }

    func clearAutosave() {
        try? fileManager.removeItem(at: autosaveURL)
    }
}
