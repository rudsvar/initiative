import Foundation

/// A full monster stat block, as the DM reads it at the table. Read-only reference
/// data: it is never edited in the app and never saved into a session.
///
/// The text comes from the System Reference Document 5.2.1 (CC BY 4.0). The
/// attribution statement is in `NOTICE`; see `Data/srd-creatures.json`.
struct StatBlock: Codable, Equatable, Identifiable {
    var id: String { name }

    let name: String
    let size: String
    let type: String
    let alignment: String
    let armorClass: Int
    let initiative: Initiative
    let hitPoints: HitPoints
    let speed: String
    let abilities: Abilities
    let skills: String?
    let gear: String?
    let senses: String
    let languages: String
    let challenge: Challenge
    let traits: [Entry]
    let actions: [Entry]

    struct Initiative: Codable, Equatable {
        /// The modifier added to the d20 roll.
        let modifier: Int
        /// The passive score in the printed stat block, `10 + modifier` for most.
        let score: Int
    }

    struct HitPoints: Codable, Equatable {
        let average: Int
        /// The dice expression the stat block prints in parentheses.
        let formula: String
    }

    struct Ability: Codable, Equatable {
        let score: Int
        let modifier: Int
        let save: Int
    }

    struct Abilities: Codable, Equatable {
        let str: Ability
        let dex: Ability
        let con: Ability
        let int: Ability
        let wis: Ability
        let cha: Ability

        private enum CodingKeys: String, CodingKey {
            case str = "Str", dex = "Dex", con = "Con", int = "Int", wis = "Wis", cha = "Cha"
        }
    }

    struct Challenge: Codable, Equatable {
        let cr: String
        let xp: Int
        let proficiencyBonus: Int
    }

    /// A named trait or action. Recharge and usage notes stay in the name, as printed.
    struct Entry: Codable, Equatable {
        let name: String
        let text: String
    }
}
