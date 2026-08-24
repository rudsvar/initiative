import Foundation

/// The creatures and encounters a fresh install starts with, and the single place
/// they're edited.
///
/// This is editorial data, not code: names are deliberately **generic folklore**
/// (goblin, wight, harpy, elemental) rather than anything specific to a
/// published ruleset, and the numbers are plausible rather than copied — they
/// exist so a session can start without typing stats in at the table, not to
/// reproduce anyone's stat block.
///
/// Encounters name their creatures rather than restating stats, and the stats are
/// resolved from `creatures` when an encounter is installed. Restating them would
/// mean two tables to keep in step, and `DefaultContentTests` pins that every
/// encounter line names a creature that actually exists here.
enum DefaultContent {

    struct Creature: Equatable {
        let name: String
        let maxHP: Int
        let armorClass: Int
        let initiativeBonus: Int
    }

    /// One line of an encounter: how many of which creature.
    struct Lineup: Equatable {
        let creature: String
        let count: Int

        init(_ creature: String, _ count: Int = 1) {
            self.creature = creature
            self.count = count
        }
    }

    struct EncounterTemplate: Equatable {
        let name: String
        let lineup: [Lineup]
    }

    // MARK: - Creatures
    //
    // Roughly ordered weakest-to-strongest within each group, though the
    // Creatures screen sorts alphabetically — the grouping is for whoever is
    // editing this list, not for the UI.

    static let creatures: [Creature] = [

        // Vermin and beasts
        Creature(name: "Giant Rat", maxHP: 7, armorClass: 12, initiativeBonus: 2),
        Creature(name: "Rat Swarm", maxHP: 24, armorClass: 10, initiativeBonus: 2),
        Creature(name: "Giant Bat", maxHP: 22, armorClass: 13, initiativeBonus: 3),
        Creature(name: "Boar", maxHP: 11, armorClass: 11, initiativeBonus: 0),
        Creature(name: "Wolf", maxHP: 11, armorClass: 13, initiativeBonus: 2),
        Creature(name: "Panther", maxHP: 13, armorClass: 12, initiativeBonus: 4),
        Creature(name: "Crocodile", maxHP: 19, armorClass: 12, initiativeBonus: 0),
        Creature(name: "Giant Toad", maxHP: 39, armorClass: 11, initiativeBonus: 0),
        Creature(name: "Giant Spider", maxHP: 26, armorClass: 14, initiativeBonus: 3),
        Creature(name: "Giant Eagle", maxHP: 26, armorClass: 13, initiativeBonus: 3),
        Creature(name: "Black Bear", maxHP: 19, armorClass: 11, initiativeBonus: 1),
        Creature(name: "Dire Wolf", maxHP: 37, armorClass: 14, initiativeBonus: 2),
        Creature(name: "Brown Bear", maxHP: 34, armorClass: 11, initiativeBonus: 1),
        Creature(name: "Giant Scorpion", maxHP: 52, armorClass: 15, initiativeBonus: 1),

        // People
        Creature(name: "Acolyte", maxHP: 9, armorClass: 10, initiativeBonus: 0),
        Creature(name: "Cultist", maxHP: 9, armorClass: 12, initiativeBonus: 1),
        Creature(name: "Tribal Warrior", maxHP: 11, armorClass: 12, initiativeBonus: 0),
        Creature(name: "Bandit", maxHP: 11, armorClass: 12, initiativeBonus: 1),
        Creature(name: "Thief", maxHP: 11, armorClass: 12, initiativeBonus: 3),
        Creature(name: "Guard", maxHP: 11, armorClass: 16, initiativeBonus: 1),
        Creature(name: "Scout", maxHP: 16, armorClass: 13, initiativeBonus: 2),
        Creature(name: "Archer", maxHP: 22, armorClass: 14, initiativeBonus: 3),
        Creature(name: "Apprentice Mage", maxHP: 22, armorClass: 12, initiativeBonus: 2),
        Creature(name: "Priest", maxHP: 27, armorClass: 13, initiativeBonus: 0),
        Creature(name: "Mercenary", maxHP: 27, armorClass: 16, initiativeBonus: 1),
        Creature(name: "Cult Fanatic", maxHP: 33, armorClass: 13, initiativeBonus: 2),
        Creature(name: "Sorcerer", maxHP: 40, armorClass: 12, initiativeBonus: 2),
        Creature(name: "Knight", maxHP: 52, armorClass: 18, initiativeBonus: 0),
        Creature(name: "Veteran", maxHP: 58, armorClass: 17, initiativeBonus: 1),
        Creature(name: "Bandit Captain", maxHP: 65, armorClass: 15, initiativeBonus: 3),
        Creature(name: "Berserker", maxHP: 67, armorClass: 13, initiativeBonus: 1),
        Creature(name: "Assassin", maxHP: 78, armorClass: 15, initiativeBonus: 4),

        // Warbands
        Creature(name: "Goblin", maxHP: 7, armorClass: 15, initiativeBonus: 2),
        Creature(name: "Orc", maxHP: 15, armorClass: 13, initiativeBonus: 1),
        Creature(name: "Hobgoblin", maxHP: 11, armorClass: 18, initiativeBonus: 1),
        Creature(name: "Goblin Boss", maxHP: 21, armorClass: 17, initiativeBonus: 2),
        Creature(name: "Ogre", maxHP: 59, armorClass: 11, initiativeBonus: -1),
        Creature(name: "Orc Warchief", maxHP: 93, armorClass: 16, initiativeBonus: 1),

        // Restless dead
        Creature(name: "Skeleton", maxHP: 13, armorClass: 13, initiativeBonus: 2),
        Creature(name: "Skeleton Archer", maxHP: 13, armorClass: 13, initiativeBonus: 3),
        Creature(name: "Shadow", maxHP: 16, armorClass: 12, initiativeBonus: 2),
        Creature(name: "Zombie", maxHP: 22, armorClass: 8, initiativeBonus: -2),
        Creature(name: "Ghoul", maxHP: 22, armorClass: 12, initiativeBonus: 2),
        Creature(name: "Specter", maxHP: 22, armorClass: 12, initiativeBonus: 2),
        Creature(name: "Wight", maxHP: 45, armorClass: 14, initiativeBonus: 1),
        Creature(name: "Mummy", maxHP: 58, armorClass: 11, initiativeBonus: -1),
        Creature(name: "Skeletal Knight", maxHP: 60, armorClass: 17, initiativeBonus: 0),
        Creature(name: "Wraith", maxHP: 67, armorClass: 13, initiativeBonus: 3),
        Creature(name: "Vampire Spawn", maxHP: 82, armorClass: 15, initiativeBonus: 3),

        // Monsters
        Creature(name: "Imp", maxHP: 10, armorClass: 13, initiativeBonus: 3),
        Creature(name: "Will-o'-Wisp", maxHP: 22, armorClass: 19, initiativeBonus: 4),
        Creature(name: "Animated Armor", maxHP: 33, armorClass: 18, initiativeBonus: 0),
        Creature(name: "Harpy", maxHP: 38, armorClass: 11, initiativeBonus: 1),
        Creature(name: "Lesser Demon", maxHP: 44, armorClass: 15, initiativeBonus: 2),
        Creature(name: "Centaur", maxHP: 45, armorClass: 12, initiativeBonus: 2),
        Creature(name: "Ooze", maxHP: 45, armorClass: 8, initiativeBonus: -3),
        Creature(name: "Gargoyle", maxHP: 52, armorClass: 15, initiativeBonus: 0),
        Creature(name: "Basilisk", maxHP: 52, armorClass: 15, initiativeBonus: 0),
        Creature(name: "Griffon", maxHP: 59, armorClass: 12, initiativeBonus: 2),
        Creature(name: "Manticore", maxHP: 68, armorClass: 14, initiativeBonus: 1),
        Creature(name: "Minotaur", maxHP: 76, armorClass: 14, initiativeBonus: 0),
        Creature(name: "Troll", maxHP: 84, armorClass: 15, initiativeBonus: 1),
        Creature(name: "Air Elemental", maxHP: 90, armorClass: 15, initiativeBonus: 5),
        Creature(name: "Fire Elemental", maxHP: 102, armorClass: 13, initiativeBonus: 3),
        Creature(name: "Hill Giant", maxHP: 105, armorClass: 13, initiativeBonus: -1),
        Creature(name: "Wyvern", maxHP: 110, armorClass: 13, initiativeBonus: 0),
        Creature(name: "Winged Devil", maxHP: 110, armorClass: 17, initiativeBonus: 2),
        Creature(name: "Earth Elemental", maxHP: 126, armorClass: 17, initiativeBonus: -1),
        Creature(name: "Stone Golem", maxHP: 178, armorClass: 17, initiativeBonus: -1),
        Creature(name: "Young Dragon", maxHP: 178, armorClass: 18, initiativeBonus: 0),
    ]

    // MARK: - Encounters
    //
    // Ordered easiest first. Each is a shape rather than a set piece — a swarm of
    // weak things, a leader with escorts, a single large threat — so they're
    // usable as-is or as a starting point to edit.

    static let encounters: [EncounterTemplate] = [
        EncounterTemplate(name: "Goblin Ambush", lineup: [
            Lineup("Goblin", 4),
            Lineup("Goblin Boss"),
        ]),
        EncounterTemplate(name: "Wolves at the Treeline", lineup: [
            Lineup("Wolf", 3),
            Lineup("Dire Wolf"),
        ]),
        EncounterTemplate(name: "Toll Bridge", lineup: [
            Lineup("Bandit", 5),
            Lineup("Archer", 2),
            Lineup("Bandit Captain"),
        ]),
        EncounterTemplate(name: "Spider Hollow", lineup: [
            Lineup("Giant Spider", 4),
            Lineup("Rat Swarm", 2),
        ]),
        EncounterTemplate(name: "The Crypt Stirs", lineup: [
            Lineup("Skeleton", 6),
            Lineup("Ghoul", 2),
            Lineup("Wight"),
        ]),
        EncounterTemplate(name: "Cult Ritual", lineup: [
            Lineup("Cultist", 6),
            Lineup("Cult Fanatic"),
            Lineup("Giant Rat", 3),
        ]),
        EncounterTemplate(name: "Bridge Troll", lineup: [
            Lineup("Troll"),
            Lineup("Boar", 2),
        ]),
        EncounterTemplate(name: "Ogre Camp", lineup: [
            Lineup("Orc", 4),
            Lineup("Ogre", 2),
            Lineup("Orc Warchief"),
        ]),
        EncounterTemplate(name: "Elemental Breach", lineup: [
            Lineup("Imp", 4),
            Lineup("Fire Elemental"),
        ]),
        EncounterTemplate(name: "The Wyrm's Approach", lineup: [
            Lineup("Cultist", 4),
            Lineup("Cult Fanatic", 2),
            Lineup("Young Dragon"),
        ]),
    ]

    // MARK: - Lookup

    static func creature(named name: String) -> Creature? {
        creatures.first { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }
    }

    /// Builds a saveable `Encounter` from a template, resolving each line's stats
    /// from the creature table. A line naming a creature that isn't in the table
    /// is dropped rather than saved without stats — but that can't happen without
    /// `DefaultContentTests` failing first.
    static func encounter(from template: EncounterTemplate) -> Encounter {
        Encounter(
            name: template.name,
            entries: template.lineup.compactMap { line in
                guard let creature = creature(named: line.creature) else { return nil }
                return EncounterEntry(
                    name: creature.name,
                    maxHP: creature.maxHP,
                    armorClass: creature.armorClass,
                    initiativeBonus: creature.initiativeBonus,
                    count: line.count
                )
            }
        )
    }
}
