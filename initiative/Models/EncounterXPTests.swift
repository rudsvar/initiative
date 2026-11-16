import XCTest
@testable import initiative

final class EncounterXPTests: XCTestCase {
    private let ratings = ["Wolf": "1/4", "Ogre": "2", "Bog Hulk": nil]

    private func estimate(_ entries: [(String, Int)]) -> EncounterXP {
        let encounter = Encounter(name: "T", entries: entries.map { EncounterEntry(name: $0.0, count: $0.1) })
        return EncounterXP.estimate(for: encounter) { entry in (ratings[entry.name] ?? nil).flatMap(ChallengeRating.xp(for:)) }
    }

    func testTotalIsEachCreaturesXPTimesItsCount() {
        let result = estimate([("Wolf", 4), ("Ogre", 1)])
        XCTAssertEqual(result.totalXP, 4 * 50 + 450)
        XCTAssertEqual(result.unratedCount, 0)
    }

    func testCreaturesWithoutARatingAreCountedNotGuessed() {
        let result = estimate([("Wolf", 2), ("Bog Hulk", 3), ("Unknown", 1)])
        XCTAssertEqual(result.totalXP, 100)
        XCTAssertEqual(result.unratedCount, 4)
    }

    /// "Worth about" the one rating whose XP is closest to the total.
    func testEstimatedRatingIsTheClosestToTheTotal() {
        XCTAssertEqual(estimate([("Wolf", 4)]).estimatedRating, "1")      // 200 XP
        XCTAssertEqual(estimate([("Ogre", 2)]).estimatedRating, "3")      // 900 is nearer 700 than 1100
        XCTAssertEqual(estimate([("Wolf", 1)]).estimatedRating, "1/4")
    }

    func testNothingRatedGivesNoEstimate() {
        XCTAssertNil(estimate([("Bog Hulk", 2)]).estimatedRating)
        XCTAssertNil(estimate([]).estimatedRating)
    }

    /// Every creature in a premade encounter is a built-in with a rating, so a
    /// premade encounter never leaves anything out of its total.
    func testEveryPremadeEncounterCreatureHasXP() throws {
        let store = PresetStore(baseDirectory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        store.installDefaults()
        for encounter in DefaultContent.encounters {
            let result = EncounterXP.estimate(for: Encounter(name: encounter.name, entries: encounter.lineup.map { EncounterEntry(name: $0.creature, count: $0.count) })) { store.overview(of: $0).challenge?.xp }
            XCTAssertEqual(result.unratedCount, 0, encounter.name)
        }
    }
}
