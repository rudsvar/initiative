import Foundation

/// The built-in creatures and premade encounters a fresh install starts with, and
/// the single place they're edited.
///
/// Every built-in creature is a stat block from the System Reference Document
/// 5.2.1, licensed under CC BY 4.0. The credit is in `NOTICE` at the repository
/// root, and it must stay there. The full stat blocks are in
/// `Data/srd-creatures.json`; this list holds the three numbers the creature
/// list shows. Creatures the owner makes are not stored here: they come from
/// cloning one of these or from scratch.
///
/// Encounters name their creatures rather than restating stats, and the stats are
/// resolved from `creatures` when an encounter is installed. `DefaultContentTests`
/// pins that every encounter line names a creature that actually exists here.
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
        Creature(name: "Aboleth", maxHP: 150, armorClass: 17, initiativeBonus: 7),  // SRD 5.2.1
        Creature(name: "Adult Black Dragon", maxHP: 195, armorClass: 19, initiativeBonus: 12),  // SRD 5.2.1
        Creature(name: "Adult Blue Dragon", maxHP: 212, armorClass: 19, initiativeBonus: 10),  // SRD 5.2.1
        Creature(name: "Adult Brass Dragon", maxHP: 172, armorClass: 18, initiativeBonus: 10),  // SRD 5.2.1
        Creature(name: "Adult Bronze Dragon", maxHP: 212, armorClass: 18, initiativeBonus: 10),  // SRD 5.2.1
        Creature(name: "Adult Copper Dragon", maxHP: 184, armorClass: 18, initiativeBonus: 11),  // SRD 5.2.1
        Creature(name: "Adult Gold Dragon", maxHP: 243, armorClass: 19, initiativeBonus: 14),  // SRD 5.2.1
        Creature(name: "Adult Green Dragon", maxHP: 207, armorClass: 19, initiativeBonus: 11),  // SRD 5.2.1
        Creature(name: "Adult Red Dragon", maxHP: 256, armorClass: 19, initiativeBonus: 12),  // SRD 5.2.1
        Creature(name: "Adult Silver Dragon", maxHP: 216, armorClass: 19, initiativeBonus: 10),  // SRD 5.2.1
        Creature(name: "Adult White Dragon", maxHP: 200, armorClass: 18, initiativeBonus: 10),  // SRD 5.2.1
        Creature(name: "Air Elemental", maxHP: 90, armorClass: 15, initiativeBonus: 5),  // SRD 5.2.1
        Creature(name: "Allosaurus", maxHP: 51, armorClass: 13, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Ancient Black Dragon", maxHP: 367, armorClass: 22, initiativeBonus: 16),  // SRD 5.2.1
        Creature(name: "Ancient Blue Dragon", maxHP: 481, armorClass: 22, initiativeBonus: 14),  // SRD 5.2.1
        Creature(name: "Ancient Brass Dragon", maxHP: 332, armorClass: 20, initiativeBonus: 12),  // SRD 5.2.1
        Creature(name: "Ancient Bronze Dragon", maxHP: 444, armorClass: 22, initiativeBonus: 14),  // SRD 5.2.1
        Creature(name: "Ancient Copper Dragon", maxHP: 367, armorClass: 21, initiativeBonus: 15),  // SRD 5.2.1
        Creature(name: "Ancient Gold Dragon", maxHP: 546, armorClass: 22, initiativeBonus: 16),  // SRD 5.2.1
        Creature(name: "Ancient Green Dragon", maxHP: 402, armorClass: 21, initiativeBonus: 15),  // SRD 5.2.1
        Creature(name: "Ancient Red Dragon", maxHP: 507, armorClass: 22, initiativeBonus: 14),  // SRD 5.2.1
        Creature(name: "Ancient Silver Dragon", maxHP: 468, armorClass: 22, initiativeBonus: 14),  // SRD 5.2.1
        Creature(name: "Ancient White Dragon", maxHP: 333, armorClass: 20, initiativeBonus: 12),  // SRD 5.2.1
        Creature(name: "Animated Armor", maxHP: 33, armorClass: 18, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Animated Flying Sword", maxHP: 14, armorClass: 17, initiativeBonus: 4),  // SRD 5.2.1
        Creature(name: "Animated Rug of Smothering", maxHP: 27, armorClass: 12, initiativeBonus: 4),  // SRD 5.2.1
        Creature(name: "Ankheg", maxHP: 45, armorClass: 14, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Ankylosaurus", maxHP: 68, armorClass: 15, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Ape", maxHP: 19, armorClass: 12, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Archelon", maxHP: 90, armorClass: 17, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Archmage", maxHP: 170, armorClass: 17, initiativeBonus: 7),  // SRD 5.2.1
        Creature(name: "Assassin", maxHP: 97, armorClass: 16, initiativeBonus: 10),  // SRD 5.2.1
        Creature(name: "Awakened Shrub", maxHP: 10, armorClass: 9, initiativeBonus: -1),  // SRD 5.2.1
        Creature(name: "Awakened Tree", maxHP: 59, armorClass: 13, initiativeBonus: -2),  // SRD 5.2.1
        Creature(name: "Axe Beak", maxHP: 19, armorClass: 11, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Azer Sentinel", maxHP: 39, armorClass: 17, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Baboon", maxHP: 3, armorClass: 12, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Badger", maxHP: 5, armorClass: 11, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Balor", maxHP: 287, armorClass: 19, initiativeBonus: 14),  // SRD 5.2.1
        Creature(name: "Bandit", maxHP: 11, armorClass: 12, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Bandit Captain", maxHP: 52, armorClass: 15, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Barbed Devil", maxHP: 110, armorClass: 15, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Basilisk", maxHP: 52, armorClass: 15, initiativeBonus: -1),  // SRD 5.2.1
        Creature(name: "Bat", maxHP: 1, armorClass: 12, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Bearded Devil", maxHP: 58, armorClass: 13, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Behir", maxHP: 168, armorClass: 17, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Berserker", maxHP: 67, armorClass: 13, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Black Bear", maxHP: 19, armorClass: 11, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Black Dragon Wyrmling", maxHP: 33, armorClass: 17, initiativeBonus: 4),  // SRD 5.2.1
        Creature(name: "Black Pudding", maxHP: 68, armorClass: 7, initiativeBonus: -3),  // SRD 5.2.1
        Creature(name: "Blink Dog", maxHP: 22, armorClass: 13, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Blood Hawk", maxHP: 7, armorClass: 12, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Blue Dragon Wyrmling", maxHP: 65, armorClass: 17, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Boar", maxHP: 13, armorClass: 11, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Bone Devil", maxHP: 161, armorClass: 16, initiativeBonus: 7),  // SRD 5.2.1
        Creature(name: "Brass Dragon Wyrmling", maxHP: 22, armorClass: 15, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Bronze Dragon Wyrmling", maxHP: 39, armorClass: 15, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Brown Bear", maxHP: 22, armorClass: 11, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Bugbear Stalker", maxHP: 65, armorClass: 15, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Bugbear Warrior", maxHP: 33, armorClass: 14, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Bulette", maxHP: 94, armorClass: 17, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Camel", maxHP: 17, armorClass: 10, initiativeBonus: -1),  // SRD 5.2.1
        Creature(name: "Cat", maxHP: 2, armorClass: 12, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Centaur Trooper", maxHP: 45, armorClass: 16, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Chain Devil", maxHP: 85, armorClass: 15, initiativeBonus: 5),  // SRD 5.2.1
        Creature(name: "Chimera", maxHP: 114, armorClass: 14, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Chuul", maxHP: 76, armorClass: 16, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Clay Golem", maxHP: 123, armorClass: 14, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Cloaker", maxHP: 91, armorClass: 14, initiativeBonus: 5),  // SRD 5.2.1
        Creature(name: "Cloud Giant", maxHP: 200, armorClass: 14, initiativeBonus: 4),  // SRD 5.2.1
        Creature(name: "Cockatrice", maxHP: 22, armorClass: 11, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Commoner", maxHP: 4, armorClass: 10, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Constrictor Snake", maxHP: 13, armorClass: 13, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Copper Dragon Wyrmling", maxHP: 22, armorClass: 16, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Couatl", maxHP: 60, armorClass: 19, initiativeBonus: 5),  // SRD 5.2.1
        Creature(name: "Crab", maxHP: 3, armorClass: 11, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Crocodile", maxHP: 13, armorClass: 12, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Cultist", maxHP: 9, armorClass: 12, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Cultist Fanatic", maxHP: 44, armorClass: 13, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Darkmantle", maxHP: 22, armorClass: 11, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Death Dog", maxHP: 39, armorClass: 12, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Deer", maxHP: 4, armorClass: 13, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Deva", maxHP: 229, armorClass: 17, initiativeBonus: 4),  // SRD 5.2.1
        Creature(name: "Dire Wolf", maxHP: 22, armorClass: 14, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Djinni", maxHP: 218, armorClass: 17, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Doppelganger", maxHP: 52, armorClass: 14, initiativeBonus: 4),  // SRD 5.2.1
        Creature(name: "Draft Horse", maxHP: 15, armorClass: 10, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Dragon Turtle", maxHP: 356, armorClass: 20, initiativeBonus: 6),  // SRD 5.2.1
        Creature(name: "Dretch", maxHP: 18, armorClass: 11, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Drider", maxHP: 123, armorClass: 19, initiativeBonus: 4),  // SRD 5.2.1
        Creature(name: "Druid", maxHP: 44, armorClass: 13, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Dryad", maxHP: 22, armorClass: 16, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Dust Mephit", maxHP: 17, armorClass: 12, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Eagle", maxHP: 4, armorClass: 12, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Earth Elemental", maxHP: 147, armorClass: 17, initiativeBonus: -1),  // SRD 5.2.1
        Creature(name: "Efreeti", maxHP: 212, armorClass: 17, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Elephant", maxHP: 76, armorClass: 12, initiativeBonus: -1),  // SRD 5.2.1
        Creature(name: "Elk", maxHP: 11, armorClass: 10, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Erinyes", maxHP: 178, armorClass: 18, initiativeBonus: 7),  // SRD 5.2.1
        Creature(name: "Ettercap", maxHP: 44, armorClass: 13, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Ettin", maxHP: 85, armorClass: 12, initiativeBonus: -1),  // SRD 5.2.1
        Creature(name: "Fire Elemental", maxHP: 93, armorClass: 13, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Fire Giant", maxHP: 162, armorClass: 18, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Flesh Golem", maxHP: 127, armorClass: 9, initiativeBonus: -1),  // SRD 5.2.1
        Creature(name: "Flying Snake", maxHP: 5, armorClass: 14, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Frog", maxHP: 1, armorClass: 11, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Frost Giant", maxHP: 149, armorClass: 15, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Gargoyle", maxHP: 67, armorClass: 15, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Gelatinous Cube", maxHP: 63, armorClass: 6, initiativeBonus: -4),  // SRD 5.2.1
        Creature(name: "Ghast", maxHP: 36, armorClass: 13, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Ghost", maxHP: 45, armorClass: 11, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Ghoul", maxHP: 22, armorClass: 12, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Giant Ape", maxHP: 168, armorClass: 12, initiativeBonus: 5),  // SRD 5.2.1
        Creature(name: "Giant Badger", maxHP: 15, armorClass: 13, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Giant Bat", maxHP: 22, armorClass: 13, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Giant Boar", maxHP: 42, armorClass: 13, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Giant Centipede", maxHP: 9, armorClass: 14, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Giant Constrictor Snake", maxHP: 60, armorClass: 12, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Giant Crab", maxHP: 13, armorClass: 15, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Giant Crocodile", maxHP: 85, armorClass: 14, initiativeBonus: -1),  // SRD 5.2.1
        Creature(name: "Giant Eagle", maxHP: 26, armorClass: 13, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Giant Elk", maxHP: 42, armorClass: 14, initiativeBonus: 6),  // SRD 5.2.1
        Creature(name: "Giant Fire Beetle", maxHP: 4, armorClass: 13, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Giant Frog", maxHP: 18, armorClass: 11, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Giant Goat", maxHP: 19, armorClass: 11, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Giant Hyena", maxHP: 45, armorClass: 12, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Giant Lizard", maxHP: 19, armorClass: 12, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Giant Octopus", maxHP: 45, armorClass: 11, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Giant Owl", maxHP: 19, armorClass: 12, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Giant Rat", maxHP: 7, armorClass: 13, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Giant Scorpion", maxHP: 52, armorClass: 15, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Giant Seahorse", maxHP: 16, armorClass: 14, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Giant Shark", maxHP: 92, armorClass: 13, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Giant Spider", maxHP: 26, armorClass: 14, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Giant Toad", maxHP: 39, armorClass: 11, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Giant Venomous Snake", maxHP: 11, armorClass: 14, initiativeBonus: 4),  // SRD 5.2.1
        Creature(name: "Giant Vulture", maxHP: 25, armorClass: 10, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Giant Wasp", maxHP: 22, armorClass: 13, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Giant Weasel", maxHP: 9, armorClass: 13, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Giant Wolf Spider", maxHP: 11, armorClass: 13, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Gibbering Mouther", maxHP: 52, armorClass: 9, initiativeBonus: -1),  // SRD 5.2.1
        Creature(name: "Glabrezu", maxHP: 189, armorClass: 17, initiativeBonus: 6),  // SRD 5.2.1
        Creature(name: "Gladiator", maxHP: 112, armorClass: 16, initiativeBonus: 5),  // SRD 5.2.1
        Creature(name: "Gnoll Warrior", maxHP: 27, armorClass: 15, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Goat", maxHP: 4, armorClass: 10, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Goblin Boss", maxHP: 21, armorClass: 17, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Goblin Minion", maxHP: 7, armorClass: 12, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Goblin Warrior", maxHP: 10, armorClass: 15, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Gold Dragon Wyrmling", maxHP: 60, armorClass: 17, initiativeBonus: 4),  // SRD 5.2.1
        Creature(name: "Gorgon", maxHP: 114, armorClass: 19, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Gray Ooze", maxHP: 22, armorClass: 9, initiativeBonus: -2),  // SRD 5.2.1
        Creature(name: "Green Dragon Wyrmling", maxHP: 38, armorClass: 17, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Green Hag", maxHP: 82, armorClass: 17, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Grick", maxHP: 54, armorClass: 14, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Griffon", maxHP: 59, armorClass: 12, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Grimlock", maxHP: 11, armorClass: 11, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Guard", maxHP: 11, armorClass: 16, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Guard Captain", maxHP: 75, armorClass: 18, initiativeBonus: 4),  // SRD 5.2.1
        Creature(name: "Guardian Naga", maxHP: 136, armorClass: 18, initiativeBonus: 4),  // SRD 5.2.1
        Creature(name: "Half-Dragon", maxHP: 105, armorClass: 18, initiativeBonus: 5),  // SRD 5.2.1
        Creature(name: "Harpy", maxHP: 38, armorClass: 11, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Hawk", maxHP: 1, armorClass: 13, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Hell Hound", maxHP: 58, armorClass: 15, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Hezrou", maxHP: 157, armorClass: 18, initiativeBonus: 6),  // SRD 5.2.1
        Creature(name: "Hill Giant", maxHP: 105, armorClass: 13, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Hippogriff", maxHP: 26, armorClass: 11, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Hippopotamus", maxHP: 82, armorClass: 14, initiativeBonus: -2),  // SRD 5.2.1
        Creature(name: "Hobgoblin Captain", maxHP: 58, armorClass: 17, initiativeBonus: 4),  // SRD 5.2.1
        Creature(name: "Hobgoblin Warrior", maxHP: 11, armorClass: 18, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Homunculus", maxHP: 4, armorClass: 13, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Horned Devil", maxHP: 199, armorClass: 18, initiativeBonus: 7),  // SRD 5.2.1
        Creature(name: "Hunter Shark", maxHP: 45, armorClass: 12, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Hydra", maxHP: 184, armorClass: 15, initiativeBonus: 4),  // SRD 5.2.1
        Creature(name: "Hyena", maxHP: 5, armorClass: 11, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Ice Devil", maxHP: 228, armorClass: 18, initiativeBonus: 7),  // SRD 5.2.1
        Creature(name: "Ice Mephit", maxHP: 21, armorClass: 11, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Imp", maxHP: 21, armorClass: 13, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Incubus", maxHP: 66, armorClass: 15, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Invisible Stalker", maxHP: 97, armorClass: 14, initiativeBonus: 7),  // SRD 5.2.1
        Creature(name: "Iron Golem", maxHP: 252, armorClass: 20, initiativeBonus: 9),  // SRD 5.2.1
        Creature(name: "Jackal", maxHP: 3, armorClass: 12, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Killer Whale", maxHP: 90, armorClass: 12, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Knight", maxHP: 52, armorClass: 18, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Kobold Warrior", maxHP: 7, armorClass: 14, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Kraken", maxHP: 481, armorClass: 18, initiativeBonus: 14),  // SRD 5.2.1
        Creature(name: "Lamia", maxHP: 97, armorClass: 13, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Lemure", maxHP: 9, armorClass: 9, initiativeBonus: -3),  // SRD 5.2.1
        Creature(name: "Lich", maxHP: 315, armorClass: 20, initiativeBonus: 17),  // SRD 5.2.1
        Creature(name: "Lion", maxHP: 22, armorClass: 12, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Lizard", maxHP: 2, armorClass: 10, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Mage", maxHP: 81, armorClass: 15, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Magma Mephit", maxHP: 18, armorClass: 11, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Magmin", maxHP: 13, armorClass: 14, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Mammoth", maxHP: 126, armorClass: 13, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Manticore", maxHP: 68, armorClass: 14, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Marilith", maxHP: 220, armorClass: 16, initiativeBonus: 10),  // SRD 5.2.1
        Creature(name: "Mastiff", maxHP: 5, armorClass: 12, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Medusa", maxHP: 127, armorClass: 15, initiativeBonus: 6),  // SRD 5.2.1
        Creature(name: "Merfolk Skirmisher", maxHP: 11, armorClass: 11, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Merrow", maxHP: 45, armorClass: 13, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Mimic", maxHP: 58, armorClass: 12, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Minotaur of Baphomet", maxHP: 85, armorClass: 14, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Minotaur Skeleton", maxHP: 45, armorClass: 12, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Mule", maxHP: 11, armorClass: 10, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Mummy", maxHP: 58, armorClass: 11, initiativeBonus: -1),  // SRD 5.2.1
        Creature(name: "Mummy Lord", maxHP: 187, armorClass: 17, initiativeBonus: 10),  // SRD 5.2.1
        Creature(name: "Nalfeshnee", maxHP: 184, armorClass: 18, initiativeBonus: 5),  // SRD 5.2.1
        Creature(name: "Night Hag", maxHP: 112, armorClass: 17, initiativeBonus: 5),  // SRD 5.2.1
        Creature(name: "Nightmare", maxHP: 68, armorClass: 13, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Noble", maxHP: 9, armorClass: 15, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Ochre Jelly", maxHP: 52, armorClass: 8, initiativeBonus: -2),  // SRD 5.2.1
        Creature(name: "Octopus", maxHP: 3, armorClass: 12, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Ogre", maxHP: 68, armorClass: 11, initiativeBonus: -1),  // SRD 5.2.1
        Creature(name: "Ogre Zombie", maxHP: 85, armorClass: 8, initiativeBonus: -2),  // SRD 5.2.1
        Creature(name: "Oni", maxHP: 119, armorClass: 17, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Otyugh", maxHP: 104, armorClass: 14, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Owl", maxHP: 1, armorClass: 11, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Owlbear", maxHP: 59, armorClass: 13, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Panther", maxHP: 13, armorClass: 13, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Pegasus", maxHP: 59, armorClass: 12, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Phase Spider", maxHP: 45, armorClass: 14, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Piranha", maxHP: 1, armorClass: 13, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Pirate", maxHP: 33, armorClass: 14, initiativeBonus: 5),  // SRD 5.2.1
        Creature(name: "Pirate Captain", maxHP: 84, armorClass: 17, initiativeBonus: 7),  // SRD 5.2.1
        Creature(name: "Pit Fiend", maxHP: 337, armorClass: 21, initiativeBonus: 14),  // SRD 5.2.1
        Creature(name: "Planetar", maxHP: 262, armorClass: 19, initiativeBonus: 10),  // SRD 5.2.1
        Creature(name: "Plesiosaurus", maxHP: 68, armorClass: 13, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Polar Bear", maxHP: 42, armorClass: 12, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Pony", maxHP: 11, armorClass: 10, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Priest", maxHP: 38, armorClass: 13, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Priest Acolyte", maxHP: 11, armorClass: 13, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Pseudodragon", maxHP: 10, armorClass: 14, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Pteranodon", maxHP: 13, armorClass: 13, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Purple Worm", maxHP: 247, armorClass: 18, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Quasit", maxHP: 25, armorClass: 13, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Rakshasa", maxHP: 221, armorClass: 17, initiativeBonus: 8),  // SRD 5.2.1
        Creature(name: "Rat", maxHP: 1, armorClass: 10, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Raven", maxHP: 2, armorClass: 12, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Red Dragon Wyrmling", maxHP: 75, armorClass: 17, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Reef Shark", maxHP: 22, armorClass: 12, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Remorhaz", maxHP: 195, armorClass: 17, initiativeBonus: 5),  // SRD 5.2.1
        Creature(name: "Rhinoceros", maxHP: 45, armorClass: 13, initiativeBonus: -1),  // SRD 5.2.1
        Creature(name: "Riding Horse", maxHP: 13, armorClass: 11, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Roc", maxHP: 248, armorClass: 15, initiativeBonus: 8),  // SRD 5.2.1
        Creature(name: "Roper", maxHP: 93, armorClass: 20, initiativeBonus: 5),  // SRD 5.2.1
        Creature(name: "Rust Monster", maxHP: 33, armorClass: 14, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Saber-Toothed Tiger", maxHP: 52, armorClass: 13, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Sahuagin Warrior", maxHP: 22, armorClass: 12, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Salamander", maxHP: 90, armorClass: 15, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Satyr", maxHP: 31, armorClass: 13, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Scorpion", maxHP: 1, armorClass: 11, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Scout", maxHP: 16, armorClass: 13, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Sea Hag", maxHP: 52, armorClass: 14, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Seahorse", maxHP: 1, armorClass: 12, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Shadow", maxHP: 27, armorClass: 12, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Shambling Mound", maxHP: 110, armorClass: 15, initiativeBonus: -1),  // SRD 5.2.1
        Creature(name: "Shield Guardian", maxHP: 142, armorClass: 17, initiativeBonus: -1),  // SRD 5.2.1
        Creature(name: "Shrieker Fungus", maxHP: 13, armorClass: 5, initiativeBonus: -5),  // SRD 5.2.1
        Creature(name: "Silver Dragon Wyrmling", maxHP: 45, armorClass: 17, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Skeleton", maxHP: 13, armorClass: 14, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Solar", maxHP: 297, armorClass: 21, initiativeBonus: 20),  // SRD 5.2.1
        Creature(name: "Specter", maxHP: 22, armorClass: 12, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Sphinx of Lore", maxHP: 170, armorClass: 17, initiativeBonus: 10),  // SRD 5.2.1
        Creature(name: "Sphinx of Valor", maxHP: 199, armorClass: 17, initiativeBonus: 12),  // SRD 5.2.1
        Creature(name: "Sphinx of Wonder", maxHP: 24, armorClass: 13, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Spider", maxHP: 1, armorClass: 12, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Spirit Naga", maxHP: 135, armorClass: 17, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Sprite", maxHP: 10, armorClass: 15, initiativeBonus: 4),  // SRD 5.2.1
        Creature(name: "Spy", maxHP: 27, armorClass: 12, initiativeBonus: 4),  // SRD 5.2.1
        Creature(name: "Steam Mephit", maxHP: 17, armorClass: 10, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Stirge", maxHP: 5, armorClass: 13, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Stone Giant", maxHP: 126, armorClass: 17, initiativeBonus: 5),  // SRD 5.2.1
        Creature(name: "Stone Golem", maxHP: 220, armorClass: 18, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Storm Giant", maxHP: 230, armorClass: 16, initiativeBonus: 7),  // SRD 5.2.1
        Creature(name: "Succubus", maxHP: 71, armorClass: 15, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Tarrasque", maxHP: 697, armorClass: 25, initiativeBonus: 18),  // SRD 5.2.1
        Creature(name: "Tiger", maxHP: 30, armorClass: 13, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Tough", maxHP: 32, armorClass: 12, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Tough Boss", maxHP: 82, armorClass: 16, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Treant", maxHP: 138, armorClass: 16, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Triceratops", maxHP: 114, armorClass: 14, initiativeBonus: -1),  // SRD 5.2.1
        Creature(name: "Troll", maxHP: 94, armorClass: 15, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Troll Limb", maxHP: 14, armorClass: 13, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Tyrannosaurus Rex", maxHP: 136, armorClass: 13, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Unicorn", maxHP: 97, armorClass: 12, initiativeBonus: 8),  // SRD 5.2.1
        Creature(name: "Vampire", maxHP: 195, armorClass: 16, initiativeBonus: 14),  // SRD 5.2.1
        Creature(name: "Vampire Familiar", maxHP: 65, armorClass: 15, initiativeBonus: 5),  // SRD 5.2.1
        Creature(name: "Vampire Spawn", maxHP: 90, armorClass: 16, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Venomous Snake", maxHP: 5, armorClass: 12, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Violet Fungus", maxHP: 18, armorClass: 5, initiativeBonus: -5),  // SRD 5.2.1
        Creature(name: "Vrock", maxHP: 152, armorClass: 15, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Vulture", maxHP: 5, armorClass: 10, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Warhorse", maxHP: 19, armorClass: 11, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Warhorse Skeleton", maxHP: 22, armorClass: 13, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Warrior Infantry", maxHP: 9, armorClass: 13, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Warrior Veteran", maxHP: 65, armorClass: 17, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Water Elemental", maxHP: 114, armorClass: 14, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Weasel", maxHP: 1, armorClass: 13, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Werebear", maxHP: 135, armorClass: 15, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Wereboar", maxHP: 97, armorClass: 15, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Wererat", maxHP: 60, armorClass: 13, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Weretiger", maxHP: 120, armorClass: 12, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Werewolf", maxHP: 71, armorClass: 15, initiativeBonus: 4),  // SRD 5.2.1
        Creature(name: "White Dragon Wyrmling", maxHP: 32, armorClass: 16, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Wight", maxHP: 82, armorClass: 14, initiativeBonus: 4),  // SRD 5.2.1
        Creature(name: "Will-o’-Wisp", maxHP: 27, armorClass: 19, initiativeBonus: 9),  // SRD 5.2.1
        Creature(name: "Winter Wolf", maxHP: 75, armorClass: 13, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Wolf", maxHP: 11, armorClass: 12, initiativeBonus: 2),  // SRD 5.2.1
        Creature(name: "Worg", maxHP: 26, armorClass: 13, initiativeBonus: 1),  // SRD 5.2.1
        Creature(name: "Wraith", maxHP: 67, armorClass: 13, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Wyvern", maxHP: 127, armorClass: 14, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Xorn", maxHP: 84, armorClass: 19, initiativeBonus: 0),  // SRD 5.2.1
        Creature(name: "Young Black Dragon", maxHP: 127, armorClass: 18, initiativeBonus: 5),  // SRD 5.2.1
        Creature(name: "Young Blue Dragon", maxHP: 152, armorClass: 18, initiativeBonus: 4),  // SRD 5.2.1
        Creature(name: "Young Brass Dragon", maxHP: 110, armorClass: 17, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Young Bronze Dragon", maxHP: 142, armorClass: 17, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Young Copper Dragon", maxHP: 119, armorClass: 17, initiativeBonus: 4),  // SRD 5.2.1
        Creature(name: "Young Gold Dragon", maxHP: 178, armorClass: 18, initiativeBonus: 6),  // SRD 5.2.1
        Creature(name: "Young Green Dragon", maxHP: 136, armorClass: 18, initiativeBonus: 4),  // SRD 5.2.1
        Creature(name: "Young Red Dragon", maxHP: 178, armorClass: 18, initiativeBonus: 4),  // SRD 5.2.1
        Creature(name: "Young Silver Dragon", maxHP: 168, armorClass: 18, initiativeBonus: 4),  // SRD 5.2.1
        Creature(name: "Young White Dragon", maxHP: 123, armorClass: 17, initiativeBonus: 3),  // SRD 5.2.1
        Creature(name: "Zombie", maxHP: 15, armorClass: 8, initiativeBonus: -2),  // SRD 5.2.1
    ]

    // MARK: - Encounters
    //
    // Ordered easiest first. Each is a shape rather than a set piece: a swarm of
    // weak things, a leader with escorts, a single large threat. Usable as-is or
    // as a starting point to edit. Every creature is from the SRD list above.

    static let encounters: [EncounterTemplate] = [
        EncounterTemplate(name: "Goblin Ambush", lineup: [
            Lineup("Goblin Warrior", 4),
            Lineup("Goblin Boss"),
        ]),
        EncounterTemplate(name: "Wolves at the Treeline", lineup: [
            Lineup("Wolf", 3),
            Lineup("Dire Wolf"),
        ]),
        EncounterTemplate(name: "Toll Bridge", lineup: [
            Lineup("Bandit", 5),
            Lineup("Scout", 2),
            Lineup("Bandit Captain"),
        ]),
        EncounterTemplate(name: "Spider Hollow", lineup: [
            Lineup("Giant Spider", 4),
            Lineup("Rat", 2),
        ]),
        EncounterTemplate(name: "The Crypt Stirs", lineup: [
            Lineup("Skeleton", 6),
            Lineup("Ghoul", 2),
            Lineup("Wight"),
        ]),
        EncounterTemplate(name: "Cult Ritual", lineup: [
            Lineup("Cultist", 6),
            Lineup("Cultist Fanatic"),
            Lineup("Rat", 3),
        ]),
        EncounterTemplate(name: "Bridge Troll", lineup: [
            Lineup("Troll"),
            Lineup("Giant Boar", 2),
        ]),
        EncounterTemplate(name: "Ogre Camp", lineup: [
            Lineup("Gnoll Warrior", 4),
            Lineup("Ogre", 2),
        ]),
        EncounterTemplate(name: "Elemental Breach", lineup: [
            Lineup("Imp", 4),
            Lineup("Fire Elemental"),
        ]),
        EncounterTemplate(name: "The Wyrm's Approach", lineup: [
            Lineup("Cultist", 4),
            Lineup("Cultist Fanatic", 2),
            Lineup("Young Red Dragon"),
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
