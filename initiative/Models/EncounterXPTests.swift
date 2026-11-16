import XCTest
@testable import initiative

final class EncounterXPTests: XCTestCase {
    private let known: [String: ChallengeInfo?] = [
        "Wolf": ChallengeInfo(rating: "1/4", xp: 50, isEstimate: false),
        "Ogre": ChallengeInfo(rating: "2", xp: 450, isEstimate: false),
        "Guess": ChallengeInfo(rating: "1", xp: 200, isEstimate: true),
    ]

    private func estimate(_ entries: [(String, Int)]) -> EncounterXP {
        let encounter = Encounter(name: "T", entries: entries.map { EncounterEntry(name: $0.0, count: $0.1) })
        return EncounterXP.estimate(for: encounter) { (known[$0.name] ?? nil) }
    }

    func testTotalIsEachCreaturesXPTimesItsCount() {
        let result = estimate([("Wolf", 4), ("Ogre", 1)])
        XCTAssertEqual(result.totalXP, 4 * 50 + 450)
        XCTAssertEqual(result.text, "Total 650 XP")
    }

    func testEstimatedCreaturesAreCountedAndTheTextSaysSo() {
        let result = estimate([("Wolf", 2), ("Guess", 3)])
        XCTAssertEqual(result.totalXP, 100 + 600)
        XCTAssertEqual(result.estimatedCount, 3)
        XCTAssertEqual(result.text, "Total 700 XP · includes estimates")
    }

    func testCreaturesWithNothingToGoOnAreLeftOut() {
        let result = estimate([("Wolf", 2), ("Bog Hulk", 3)])
        XCTAssertEqual(result.totalXP, 100)
        XCTAssertEqual(result.unratedCount, 3)
    }

    func testNothingRatedGivesNoText() {
        XCTAssertNil(estimate([("Bog Hulk", 2)]).text)
        XCTAssertNil(estimate([]).text)
    }

    /// Every creature in a premade encounter is a built-in with a rating, so a
    /// premade encounter never leaves anything out of its total.
    func testEveryPremadeEncounterCreatureHasXP() throws {
        let store = PresetStore(baseDirectory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
        store.installDefaults()
        for encounter in DefaultContent.encounters {
            let result = EncounterXP.estimate(for: Encounter(name: encounter.name, entries: encounter.lineup.map { EncounterEntry(name: $0.creature, count: $0.count) })) { store.overview(of: $0).challenge }
            XCTAssertEqual(result.unratedCount, 0, encounter.name)
        }
    }
}
