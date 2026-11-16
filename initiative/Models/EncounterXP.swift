import Foundation

/// What an encounter is worth: the XP of its creatures added up, and the single
/// challenge rating that total is closest to. It is an estimate for planning, not
/// a difficulty rating: it ignores party size and level.
struct EncounterXP: Equatable {
    var totalXP: Int
    /// The rating whose XP is nearest the total; nil when nothing in the encounter has one.
    var estimatedRating: String?
    /// Creatures with no rating, left out of the total rather than guessed at.
    var unratedCount: Int

    /// `xp` answers an entry with the XP one of it is worth, if that is known.
    static func estimate(for encounter: Encounter, xp: (EncounterEntry) -> Int?) -> EncounterXP {
        var total = 0
        var unrated = 0
        var anyRated = false
        for entry in encounter.entries {
            if let worth = xp(entry) {
                total += worth * entry.count
                anyRated = true
            } else {
                unrated += entry.count
            }
        }
        let nearest = anyRated
            ? ChallengeRating.all.min { abs((ChallengeRating.xp(for: $0) ?? 0) - total) < abs((ChallengeRating.xp(for: $1) ?? 0) - total) }
            : nil
        return EncounterXP(totalXP: total, estimatedRating: nearest, unratedCount: unrated)
    }
}
