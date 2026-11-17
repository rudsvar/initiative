import Foundation

/// A reusable combatant template — just enough to prefill the add-combatant modal.
struct CreaturePreset: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var maxHP: Int?
    var armorClass: Int?
    /// Flat modifier added to a random 1...20 roll when spawning from this preset.
    /// Only applies when initiative is rolled, never on top of an explicit value.
    var initiativeBonus: Int?
    /// Whether combatants spawned from this are party members rather than
    /// something the party is fighting. Defaults to **false**: a character is chosen
    /// on purpose (the Characters screen and clone set it), never assumed.
    var isPlayer: Bool = false
    /// Challenge rating as printed ("1/4", "3"), one of `ChallengeRating.all`. Set on
    /// entries the owner made or cloned; built-ins take theirs from the stat block
    /// (see `effectiveChallengeRating`).
    var challengeRating: String?

    /// What the screens show: the owner's own value, else the built-in's.
    var effectiveChallengeRating: String? {
        challengeRating ?? SRDCatalog.block(named: name)?.challenge.cr
    }

    /// The XP it is worth: a built-in's own stat block prints it, anything else
    /// comes from its rating.
    var effectiveXP: Int? {
        if let printed = SRDCatalog.block(named: name)?.challenge.xp, challengeRating == nil {
            return printed
        }
        return challengeRating.flatMap(ChallengeRating.xp(for:))
    }

    /// Rating and XP for display. The owner's rating, else the built-in's, else an
    /// estimate from hit points and armor class (marked as one); nil when there is
    /// nothing to go on.
    var challenge: ChallengeInfo? {
        if let rating = effectiveChallengeRating, let xp = effectiveXP {
            return ChallengeInfo(rating: rating, xp: xp, isEstimate: false)
        }
        guard let rating = ChallengeEstimator.shared.estimate(maxHP: maxHP, armorClass: armorClass),
              let xp = ChallengeRating.xp(for: rating) else { return nil }
        return ChallengeInfo(rating: rating, xp: xp, isEstimate: true)
    }

    init(
        id: UUID = UUID(),
        name: String,
        maxHP: Int? = nil,
        armorClass: Int? = nil,
        initiativeBonus: Int? = nil,
        isPlayer: Bool = false,
        challengeRating: String? = nil
    ) {
        self.id = id
        self.name = name
        self.maxHP = maxHP
        self.armorClass = armorClass
        self.initiativeBonus = initiativeBonus
        self.isPlayer = isPlayer
        self.challengeRating = challengeRating
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, maxHP, armorClass, initiativeBonus, isPlayer, challengeRating
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
        challengeRating = try container.decodeIfPresent(String.self, forKey: .challengeRating)
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

    /// Removes every creature the owner made, once. Built-in creatures are left
    /// alone; `installDefaults` restores any that are missing. `key` records that
    /// the clean-up has run, so it does not repeat on later launches.
    func removeUserCreatures(once key: String, defaults: UserDefaults = .standard) {
        guard !defaults.bool(forKey: key) else { return }
        for preset in listPresets() where !preset.isBuiltIn {
            delete(id: preset.id)
        }
        defaults.set(true, forKey: key)
    }

    /// Every saved preset, decoded once and kept until something is saved or deleted.
    /// Screens ask for it on every redraw (each encounter row looks up its creatures),
    /// and reading hundreds of files each time made scrolling and swiping stutter.
    @ObservationIgnored private var cache: [CreaturePreset]?

    func listPresets() -> [CreaturePreset] {
        if let cache { return cache }
        let loaded = readPresets()
        cache = loaded
        return loaded
    }

    private func readPresets() -> [CreaturePreset] {
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
        cache = nil
    }

    func delete(id: UUID) {
        let url = baseDirectory.appendingPathComponent("\(id.uuidString).json")
        try? fileManager.removeItem(at: url)
        cache = nil
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
    func upsert(name: String, maxHP: Int?, armorClass: Int? = nil, initiativeBonus: Int? = nil, isPlayer: Bool = false) {
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
    func clone(_ preset: CreaturePreset, named name: String, isPlayer: Bool, stats: CloneStats? = nil) -> CreaturePreset {
        let stats = stats ?? CloneStats(preset)
        let copy = CreaturePreset(
            name: name.trimmingCharacters(in: .whitespaces),
            maxHP: stats.maxHP,
            armorClass: stats.armorClass,
            initiativeBonus: stats.initiativeBonus,
            isPlayer: isPlayer,
            challengeRating: stats.challengeRating
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

    /// Whether an entry may be saved under `name`: not blank, and not the name of
    /// another entry or of a built-in (built-in status goes by name, so a copy
    /// under a built-in's name would turn read-only). `id` is the entry being
    /// renamed, which may keep its own name.
    func isNameAvailable(_ name: String, excluding id: UUID? = nil) -> Bool {
        let taken = listPresets().filter { $0.id != id }.map(\.name) + DefaultContent.creatures.map(\.name)
        return CloneName.isValid(name, avoiding: taken)
    }

    #if DEBUG
    /// Debug builds only: adds the made-up characters that are missing.
    func installTestCharacters() {
        let existingNames = Set(listPresets().map { $0.name.lowercased() })
        for character in TestCharacters.all where !existingNames.contains(character.name.lowercased()) {
            save(character)
        }
    }
    #endif
}

private extension DefaultContent.Creature {
    var asPreset: CreaturePreset {
        // Every built-in is something the party fights, never one of them.
        CreaturePreset(name: name, maxHP: maxHP, armorClass: armorClass, initiativeBonus: initiativeBonus, isPlayer: false)
    }
}
