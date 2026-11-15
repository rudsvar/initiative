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
    /// Whether combatants spawned from this are party members rather than
    /// something the party is fighting. Defaults to **true** for anything the user
    /// creates by hand: the built-in roster already covers the bestiary, so a
    /// creature typed in from scratch is most often a player. Every built-in is
    /// explicitly `false`.
    var isPlayer: Bool = true

    init(
        id: UUID = UUID(),
        name: String,
        maxHP: Int? = nil,
        armorClass: Int? = nil,
        initiativeBonus: Int? = nil,
        isPlayer: Bool = true
    ) {
        self.id = id
        self.name = name
        self.maxHP = maxHP
        self.armorClass = armorClass
        self.initiativeBonus = initiativeBonus
        self.isPlayer = isPlayer
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, maxHP, armorClass, initiativeBonus, isPlayer
    }

    /// Hand-written so presets saved before this field existed still decode. They
    /// predate the distinction entirely, and the safe reading of "unknown" is
    /// **not a player**: an NPC behaves exactly as everything did before death
    /// saves existed.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        maxHP = try container.decodeIfPresent(Int.self, forKey: .maxHP)
        armorClass = try container.decodeIfPresent(Int.self, forKey: .armorClass)
        initiativeBonus = try container.decodeIfPresent(Int.self, forKey: .initiativeBonus)
        isPlayer = try container.decodeIfPresent(Bool.self, forKey: .isPlayer) ?? false
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
    ///
    /// **Built-in creatures are never modified by this.** Adding a combatant
    /// called "Goblin" with 12 HP would otherwise quietly rewrite the built-in
    /// Goblin's stats — an edit to read-only content through the back door.
    /// Nothing is saved in that case; to keep customised stats, copy the built-in
    /// and name the copy.
    func upsert(name: String, maxHP: Int?, armorClass: Int? = nil, initiativeBonus: Int? = nil, isPlayer: Bool = true) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if var existing = preset(named: trimmed) {
            guard !existing.isBuiltIn else { return }
            existing.maxHP = maxHP ?? existing.maxHP
            existing.armorClass = armorClass ?? existing.armorClass
            existing.initiativeBonus = initiativeBonus ?? existing.initiativeBonus
            save(existing)
        } else {
            save(CreaturePreset(name: trimmed, maxHP: maxHP, armorClass: armorClass, initiativeBonus: initiativeBonus, isPlayer: isPlayer))
        }
    }

    /// Saves an editable copy of a preset under the name the owner chose, and
    /// returns it. The caller checks the name with `CloneName.isValid` first.
    /// This is the only route from a built-in creature to a customised one.
    @discardableResult
    func clone(_ preset: CreaturePreset, named name: String) -> CreaturePreset {
        let copy = CreaturePreset(
            name: name.trimmingCharacters(in: .whitespaces),
            maxHP: preset.maxHP,
            armorClass: preset.armorClass,
            initiativeBonus: preset.initiativeBonus,
            isPlayer: preset.isPlayer
        )
        save(copy)
        return copy
    }

    /// Ensures every built-in creature is present, **in addition to** whatever the
    /// user has. Called on every launch.
    ///
    /// Built-in creatures are permanent fixtures — the Creatures screen offers no
    /// way to delete one — so "not currently present" can only mean new in this
    /// version, or renamed into something of the user's own. Either way the right
    /// answer is to put it there, which is why this is a plain
    /// what's-missing check with no memory of what has been installed before.
    ///
    /// A preset the user already has under a built-in's name is left exactly as
    /// it is; their edits are never overwritten by the default.
    func installDefaults() {
        let existingNames = Set(listPresets().map { $0.name.lowercased() })
        for creature in DefaultContent.creatures where !existingNames.contains(creature.name.lowercased()) {
            save(creature.asPreset)
        }
    }
}

private extension DefaultContent.Creature {
    var asPreset: CreaturePreset {
        // Every built-in is something the party fights, never one of them.
        CreaturePreset(name: name, maxHP: maxHP, armorClass: armorClass, initiativeBonus: initiativeBonus, isPlayer: false)
    }
}
