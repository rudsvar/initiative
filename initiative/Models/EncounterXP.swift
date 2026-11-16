import Foundation

/// What an encounter is worth: the XP of its creatures added up. That is how the
/// rules measure an encounter (there is no "encounter CR"); the sum is meant to be
/// compared with what the party can handle. It ignores party size and level.
struct EncounterXP: Equatable {
    var totalXP: Int
    /// Creatures whose XP is worked out from hit points rather than known.
    var estimatedCount: Int
    /// Creatures with nothing to go on, left out of the total.
    var unratedCount: Int
    /// Whether anything at all was rated.
    var hasAny: Bool

    /// `challenge` answers an entry with what one of it is worth, if that is known.
    static func estimate(for encounter: Encounter, challenge: (EncounterEntry) -> ChallengeInfo?) -> EncounterXP {
        var result = EncounterXP(totalXP: 0, estimatedCount: 0, unratedCount: 0, hasAny: false)
        for entry in encounter.entries {
            if let info = challenge(entry) {
                result.totalXP += info.xp * entry.count
                result.hasAny = true
                if info.isEstimate { result.estimatedCount += entry.count }
            } else {
                result.unratedCount += entry.count
            }
        }
        return result
    }

    /// "Total 900 XP", and when any of it is estimated, says so.
    var text: String? {
        guard hasAny else { return nil }
        return "Total \(totalXP) XP" + (estimatedCount > 0 ? " · includes estimates" : "")
    }
}
