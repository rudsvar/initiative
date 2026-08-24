import Foundation

/// A reusable combatant template — just enough to prefill the add-combatant modal.
struct CreaturePreset: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var maxHP: Int?
    var armorClass: Int?
    /// Flat modifier added to a random 1...20 roll when spawning from this preset.
    /// Only applies when initiative is rolled, never on top of an explicit value.
    var initiativeBonus: Int?

    init(id: UUID = UUID(), name: String, maxHP: Int? = nil, armorClass: Int? = nil, initiativeBonus: Int? = nil) {
        self.id = id
        self.name = name
        self.maxHP = maxHP
        self.armorClass = armorClass
        self.initiativeBonus = initiativeBonus
    }
}

/// Persists creature presets as one JSON file per preset, mirroring SessionStore's
/// pattern. Presets accumulate automatically as combatants are added (see `upsert`) —
/// there's no explicit "save as preset" step in the add-combatant flow.
@Observable
class PresetStore {
    private let fileManager = FileManager.default
    private let baseDirectory: URL
    private let ledger: DefaultInstallLedger

    init(baseDirectory: URL? = nil, defaults: UserDefaults = .standard) {
        let directory = baseDirectory
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("Presets", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.baseDirectory = directory
        self.ledger = DefaultInstallLedger(defaults: defaults, key: "installedDefaultCreatures")
    }

    func listPresets() -> [CreaturePreset] {
        guard let files = try? fileManager.contentsOfDirectory(at: baseDirectory, includingPropertiesForKeys: nil) else {
            return []
        }
        return files
            .compactMap { url -> CreaturePreset? in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? JSONDecoder().decode(CreaturePreset.self, from: data)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func save(_ preset: CreaturePreset) {
        let url = baseDirectory.appendingPathComponent("\(preset.id.uuidString).json")
        guard let data = try? JSONEncoder().encode(preset) else { return }
        try? data.write(to: url)
    }

    func delete(id: UUID) {
        let url = baseDirectory.appendingPathComponent("\(id.uuidString).json")
        try? fileManager.removeItem(at: url)
    }

    func preset(named name: String) -> CreaturePreset? {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return listPresets().first { $0.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }
    }

    /// Creates a new preset or updates the existing one with a case-insensitive
    /// matching name. Called automatically whenever a combatant is added, so
    /// creature "kinds" become reusable without any explicit save action.
    func upsert(name: String, maxHP: Int?, armorClass: Int? = nil, initiativeBonus: Int? = nil) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if var existing = preset(named: trimmed) {
            existing.maxHP = maxHP ?? existing.maxHP
            existing.armorClass = armorClass ?? existing.armorClass
            existing.initiativeBonus = initiativeBonus ?? existing.initiativeBonus
            save(existing)
        } else {
            save(CreaturePreset(name: trimmed, maxHP: maxHP, armorClass: armorClass, initiativeBonus: initiativeBonus))
        }
    }

    /// Installs any default creature this install has never been offered before,
    /// **in addition to** whatever the user already has. Called on every launch.
    ///
    /// Three cases, all deliberate (see `DefaultInstallLedger`):
    /// - never offered, not present → installed
    /// - never offered, but the user already has a preset by that name → left
    ///   alone and recorded as offered, so their version is never overwritten
    /// - offered before but now absent → the user deleted it; stays deleted
    func installNewDefaults() {
        let existingNames = Set(listPresets().map { $0.name.lowercased() })
        var offered: [String] = []

        for creature in DefaultContent.creatures where !ledger.contains(creature.name) {
            offered.append(creature.name)
            guard !existingNames.contains(creature.name.lowercased()) else { continue }
            save(creature.asPreset)
        }

        ledger.markInstalled(offered)
    }

    /// Adds back every default creature not currently present, without touching
    /// existing presets (including ones that started as a default but were since
    /// edited). This is the one thing that overrides a deliberate deletion, which
    /// is why it's an explicit action behind the Creatures screen's menu rather
    /// than anything automatic.
    func restoreMissingDefaults() {
        let existingNames = Set(listPresets().map { $0.name.lowercased() })
        for creature in DefaultContent.creatures where !existingNames.contains(creature.name.lowercased()) {
            save(creature.asPreset)
        }
        ledger.markInstalled(DefaultContent.creatures.map(\.name))
    }
}

private extension DefaultContent.Creature {
    var asPreset: CreaturePreset {
        CreaturePreset(name: name, maxHP: maxHP, armorClass: armorClass, initiativeBonus: initiativeBonus)
    }
}
