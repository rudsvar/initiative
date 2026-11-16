import Foundation

/// Guesses a challenge rating for a creature that has none, from its hit points
/// and armor class, the only numbers a saved creature has.
///
/// The benchmarks are built from the built-in stat blocks: for each rating, the
/// median hit points, armor class and attack bonus of the creatures printed at it.
/// A creature's staying power is its hit points divided by the chance an attacker
/// of that rating hits its armor class (an expected-value duel, no dice, the same
/// assumption the premade balance test makes). Its estimate is the rating whose
/// benchmark creature has the closest staying power.
///
/// It sees defence only: damage, spells and special abilities are unknown for a
/// saved creature, so this is a guide and is shown as an estimate.
struct ChallengeEstimator {
    private struct Benchmark {
        let rating: String
        let hitPoints: Double
        let armorClass: Double
        let attackBonus: Double
        /// Hit points over the chance of being hit. Never lower than the rating below.
        let stayingPower: Double
    }

    private let benchmarks: [Benchmark]

    /// The estimator the app uses, built once from the bundled stat blocks.
    static let shared = ChallengeEstimator(blocks: SRDCatalog.bundled)

    init(blocks: [StatBlock]) {
        var byRating: [String: [StatBlock]] = [:]
        for block in blocks { byRating[block.challenge.cr, default: []].append(block) }
        var raw: [Benchmark] = []
        var bonusFloor = 0.0
        var powerFloor = 0.0
        for (index, rating) in ChallengeRating.all.enumerated() {
            guard let group = byRating[rating], !group.isEmpty else { continue }
            let bonuses = group.compactMap(\.firstAttackBonus).map(Double.init)
            let hitPoints = Self.median(group.map { Double($0.hitPoints.average) })
            let armorClass = Self.median(group.map { Double($0.armorClass) })
            // A rating with no attack roll among its creatures borrows a typical
            // bonus for its tier, so the comparison still has a hit chance.
            // Bonus and staying power only ever rise with the rating, so a few odd
            // creatures cannot make a tougher creature estimate lower.
            bonusFloor = max(bonusFloor, bonuses.isEmpty ? Double(3 + index / 3) : Self.median(bonuses))
            powerFloor = max(powerFloor, hitPoints / Self.hitChance(armorClass: armorClass, attackBonus: bonusFloor))
            raw.append(Benchmark(rating: rating, hitPoints: hitPoints, armorClass: armorClass, attackBonus: bonusFloor, stayingPower: powerFloor))
        }
        benchmarks = raw
    }

    /// Nil when there are no hit points to go on.
    func estimate(maxHP: Int?, armorClass: Int?) -> String? {
        guard let maxHP, maxHP > 0, !benchmarks.isEmpty else { return nil }
        let hp = Double(maxHP)
        return benchmarks.min { lhs, rhs in
            distance(hp, armorClass, to: lhs) < distance(hp, armorClass, to: rhs)
        }?.rating
    }

    private func distance(_ hp: Double, _ armorClass: Int?, to benchmark: Benchmark) -> Double {
        let ac = armorClass.map(Double.init) ?? benchmark.armorClass
        let mine = hp / Self.hitChance(armorClass: ac, attackBonus: benchmark.attackBonus)
        return abs(log(mine) - log(benchmark.stayingPower))
    }

    /// d20 + bonus reaching the armor class, with a natural 1 always missing and a 20 always hitting.
    private static func hitChance(armorClass: Double, attackBonus: Double) -> Double {
        min(0.95, max(0.05, (21 - (armorClass - attackBonus)) / 20))
    }

    private static func median(_ values: [Double]) -> Double {
        let sorted = values.sorted()
        let mid = sorted.count / 2
        return sorted.count % 2 == 1 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2
    }
}

extension StatBlock {
    /// The attack bonus of the first action with an attack roll, if any.
    var firstAttackBonus: Int? {
        for entry in actions {
            guard let range = entry.text.range(of: #"Attack Roll: \+?(\d+)"#, options: .regularExpression) else { continue }
            let digits = entry.text[range].filter(\.isNumber)
            if let bonus = Int(digits) { return bonus }
        }
        return nil
    }
}

/// A creature's challenge as the screens show it.
struct ChallengeInfo: Equatable {
    let rating: String
    let xp: Int
    /// True when the rating was worked out from hit points and armor class rather
    /// than printed or chosen by the owner.
    let isEstimate: Bool
}
