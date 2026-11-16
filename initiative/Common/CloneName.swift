import Foundation

/// The name a clone is saved under. There is no default: the owner types it,
/// so a copy never appears as "Goblin Copy" without them choosing that.
///
/// Names match the way the stores look names up: case-insensitive, with
/// surrounding spaces ignored.
enum CloneName {
    static func isValid(_ name: String, avoiding existing: [String]) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        return !existing.contains { $0.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }
    }
}

/// The numbers a creature clone starts with and the owner may change in the clone
/// sheet. Blank means no value.
struct CloneStats: Equatable {
    var maxHP: Int?
    var armorClass: Int?
    var initiativeBonus: Int?
    var challengeRating: String?

    init(maxHP: Int?, armorClass: Int?, initiativeBonus: Int?, challengeRating: String?) {
        self.maxHP = maxHP
        self.armorClass = armorClass
        self.initiativeBonus = initiativeBonus
        self.challengeRating = challengeRating
    }

    init(_ preset: CreaturePreset) {
        self.init(maxHP: preset.maxHP, armorClass: preset.armorClass, initiativeBonus: preset.initiativeBonus, challengeRating: preset.effectiveChallengeRating)
    }
}
