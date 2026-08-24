import Foundation

/// One creature "line" within a saved encounter — a snapshot of stats (not a live
/// reference to a CreaturePreset, so the encounter stays meaningful even if that
/// preset is later edited or deleted).
struct EncounterEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var maxHP: Int?
    var armorClass: Int?
    var initiativeBonus: Int?
    var count: Int

    init(
        id: UUID = UUID(),
        name: String,
        maxHP: Int? = nil,
        armorClass: Int? = nil,
        initiativeBonus: Int? = nil,
        count: Int = 1
    ) {
        self.id = id
        self.name = name
        self.maxHP = maxHP
        self.armorClass = armorClass
        self.initiativeBonus = initiativeBonus
        self.count = max(1, count)
    }
}

/// A named, reusable list of creatures — prepared ahead of time so a session can be
/// started already populated, instead of adding combatants one at a time at the table.
struct Encounter: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var entries: [EncounterEntry]

    init(id: UUID = UUID(), name: String, entries: [EncounterEntry] = []) {
        self.id = id
        self.name = name
        self.entries = entries
    }
}

/// Persists encounters as one JSON file per encounter, mirroring SessionStore/PresetStore.
@Observable
class EncounterStore {
    private let fileManager = FileManager.default
    private let baseDirectory: URL
    private let ledger: DefaultInstallLedger

    init(baseDirectory: URL? = nil, defaults: UserDefaults = .standard) {
        let directory = baseDirectory
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("Encounters", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.baseDirectory = directory
        self.ledger = DefaultInstallLedger(defaults: defaults, key: "installedDefaultEncounters")
    }

    func listEncounters() -> [Encounter] {
        guard let files = try? fileManager.contentsOfDirectory(at: baseDirectory, includingPropertiesForKeys: nil) else {
            return []
        }
        return files
            .compactMap { url -> Encounter? in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? JSONDecoder().decode(Encounter.self, from: data)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func save(_ encounter: Encounter) {
        let url = baseDirectory.appendingPathComponent("\(encounter.id.uuidString).json")
        guard let data = try? JSONEncoder().encode(encounter) else { return }
        try? data.write(to: url)
    }

    func delete(id: UUID) {
        let url = baseDirectory.appendingPathComponent("\(id.uuidString).json")
        try? fileManager.removeItem(at: url)
    }

    /// Installs any default encounter this install has never been offered before,
    /// alongside whatever the user has built themselves. Same three-case rule as
    /// `PresetStore.installNewDefaults()` — see `DefaultInstallLedger`.
    func installNewDefaults() {
        let existingNames = Set(listEncounters().map { $0.name.lowercased() })
        var offered: [String] = []

        for template in DefaultContent.encounters where !ledger.contains(template.name) {
            offered.append(template.name)
            guard !existingNames.contains(template.name.lowercased()) else { continue }
            save(DefaultContent.encounter(from: template))
        }

        ledger.markInstalled(offered)
    }

    /// Adds back every default encounter not currently present, leaving existing
    /// ones (edited or not) untouched. Explicit action only — it's the one thing
    /// that overrides a deliberate deletion.
    func restoreMissingDefaults() {
        let existingNames = Set(listEncounters().map { $0.name.lowercased() })
        for template in DefaultContent.encounters where !existingNames.contains(template.name.lowercased()) {
            save(DefaultContent.encounter(from: template))
        }
        ledger.markInstalled(DefaultContent.encounters.map(\.name))
    }
}
