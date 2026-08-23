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

    init(baseDirectory: URL? = nil) {
        let directory = baseDirectory
            ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("Presets", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.baseDirectory = directory
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

    /// Populates the store with generic starter presets, but only if it's currently
    /// empty — never overwrites presets a person has already accumulated/edited.
    func seedDefaultsIfEmpty() {
        guard listPresets().isEmpty else { return }
        for defaultPreset in CreaturePreset.defaults {
            save(CreaturePreset(
                name: defaultPreset.name,
                maxHP: defaultPreset.maxHP,
                armorClass: defaultPreset.armorClass,
                initiativeBonus: defaultPreset.initiativeBonus
            ))
        }
    }
}

extension CreaturePreset {
    /// Generic fantasy-archetype starter presets — HP, AC, and initiative bonus
    /// figures chosen to feel like plausible low-level creature stats, expressed
    /// only in our own generic terms (no naming/reference to any specific
    /// tabletop ruleset).
    static let defaults: [(name: String, maxHP: Int, armorClass: Int, initiativeBonus: Int)] = [
        ("Goblin", 7, 15, 2),
        ("Skeleton", 13, 13, 2),
        ("Thief", 11, 12, 3),
        ("Orc", 15, 13, 1),
        ("Wolf", 11, 13, 2),
        ("Zombie", 22, 8, -2),
        ("Guard", 11, 16, 1),
        ("Ogre", 59, 11, -1),
        ("Giant Spider", 26, 14, 3),
        ("Giant Rat", 7, 12, 2),
        ("Cultist", 9, 12, 1),
    ]
}
