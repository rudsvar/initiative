import XCTest
@testable import initiative

/// Only built-in (SRD) creatures are used as data here.
final class ChallengeEstimatorTests: XCTestCase {
    private let blocks = SRDCatalog.bundled

    private func steps(_ a: String, _ b: String) -> Int {
        abs((ChallengeRating.all.firstIndex(of: a) ?? 0) - (ChallengeRating.all.firstIndex(of: b) ?? 0))
    }

    /// Honest accuracy: each creature is estimated from benchmarks that leave it
    /// out, so it cannot agree with itself.
    func testEstimateFromHPAndACIsCloseToThePrintedRatingForUnseenCreatures() {
        var within1 = 0, within2 = 0, total = 0
        for block in blocks where block.hitPoints.average > 0 {
            let others = blocks.filter { $0.name != block.name }
            let estimate = ChallengeEstimator(blocks: others)
                .estimate(maxHP: block.hitPoints.average, armorClass: block.armorClass)
            let distance = steps(estimate ?? "0", block.challenge.cr)
            total += 1
            if distance <= 1 { within1 += 1 }
            if distance <= 2 { within2 += 1 }
        }
        XCTAssertGreaterThan(Double(within1) / Double(total), 0.8)
        XCTAssertGreaterThan(Double(within2) / Double(total), 0.9)
    }

    func testNoHitPointsMeansNoEstimate() {
        let estimator = ChallengeEstimator(blocks: blocks)
        XCTAssertNil(estimator.estimate(maxHP: nil, armorClass: 15))
        XCTAssertNil(estimator.estimate(maxHP: 0, armorClass: 15))
    }

    func testMoreHitPointsNeverLowersTheEstimate() {
        let estimator = ChallengeEstimator(blocks: blocks)
        var last = -1
        for hp in stride(from: 5, through: 400, by: 5) {
            let index = ChallengeRating.all.firstIndex(of: estimator.estimate(maxHP: hp, armorClass: 14)!)!
            XCTAssertGreaterThanOrEqual(index, last, "hp \(hp)")
            last = index
        }
    }

    func testMissingArmorClassStillGivesAnEstimate() {
        XCTAssertNotNil(ChallengeEstimator(blocks: blocks).estimate(maxHP: 40, armorClass: nil))
    }

    func testOwnOrBuiltInRatingIsNotAnEstimate() {
        let own = CreaturePreset(name: "Bog Hulk", maxHP: 40, armorClass: 14, challengeRating: "3").challenge
        XCTAssertEqual(own?.rating, "3")
        XCTAssertEqual(own?.xp, 700)
        XCTAssertEqual(own?.isEstimate, false)
        XCTAssertEqual(CreaturePreset(name: "Wolf", isPlayer: false).challenge?.isEstimate, false)
    }

    func testUnratedCreatureWithHitPointsIsEstimated() throws {
        let challenge = try XCTUnwrap(CreaturePreset(name: "Bog Hulk", maxHP: 40, armorClass: 14).challenge)
        XCTAssertTrue(challenge.isEstimate)
        XCTAssertEqual(challenge.xp, ChallengeRating.xp(for: challenge.rating))
    }

    func testUnratedCreatureWithoutHitPointsHasNothing() {
        XCTAssertNil(CreaturePreset(name: "Bog Hulk").challenge)
    }
}
