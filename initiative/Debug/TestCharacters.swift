#if DEBUG
import Foundation

/// A few made-up characters for debug builds, so the Characters screen, the
/// add-combatant picker and the test scenarios have something to show without
/// typing characters in first. They are ordinary characters of the owner's (they can
/// be edited and cloned), added on launch when missing. Compiled out of Release.
enum TestCharacters {
    static let all: [CreaturePreset] = [
        CreaturePreset(name: "Aria", maxHP: 38, armorClass: 16, initiativeBonus: 2, isPlayer: true, challengeRating: nil),
        CreaturePreset(name: "Brom", maxHP: 52, armorClass: 18, initiativeBonus: 0, isPlayer: true, challengeRating: nil),
        CreaturePreset(name: "Cael", maxHP: 29, armorClass: 13, initiativeBonus: 3, isPlayer: true, challengeRating: nil),
    ]
}
#endif
