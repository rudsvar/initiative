import XCTest
@testable import initiative

final class ChallengeRatingTests: XCTestCase {
    /// The table gives the XP of a creature the owner made. It should agree with the
    /// built-in stat blocks, which carry their own printed XP. Known differences:
    /// CR 0 creatures are printed as 0 or 10 XP, and the data's Archmage prints
    /// 8000 where the table has 8400 (to be checked against the source).
    func testTableAgreesWithBuiltInStatBlocksExceptKnownOnes() {
        let differing = SRDCatalog.bundled
            .filter { $0.challenge.cr != "0" && ChallengeRating.xp(for: $0.challenge.cr) != $0.challenge.xp }
            .map(\.name)
        XCTAssertEqual(differing, ["Archmage"])
    }

    /// A built-in is worth what its own stat block prints; one the owner made, what the table says.
    func testWorthPrefersTheStatBlockThenTheTable() {
        XCTAssertEqual(CreaturePreset(name: "Archmage", isPlayer: false).effectiveXP, 8000)
        XCTAssertEqual(CreaturePreset(name: "Bog Hulk", challengeRating: "3").effectiveXP, 700)
        XCTAssertNil(CreaturePreset(name: "Bog Hulk").effectiveXP)
    }

    func testUnknownRatingHasNoXP() {
        XCTAssertNil(ChallengeRating.xp(for: "31"))
        XCTAssertNil(ChallengeRating.xp(for: "lots"))
    }

    func testBuiltInCreatureShowsItsStatBlockRating() {
        let wolf = CreaturePreset(name: "Wolf", isPlayer: false)
        XCTAssertEqual(wolf.effectiveChallengeRating, "1/4")
    }

    func testOwnRatingWinsAndAbsentMeansNone() {
        XCTAssertEqual(CreaturePreset(name: "Bog Hulk", challengeRating: "3").effectiveChallengeRating, "3")
        XCTAssertNil(CreaturePreset(name: "Bog Hulk").effectiveChallengeRating)
    }

    func testPresetSavedBeforeRatingsExistedDecodes() throws {
        let json = Data(#"{"id":"\#(UUID().uuidString)","name":"Old","maxHP":5}"#.utf8)
        XCTAssertNil(try JSONDecoder().decode(CreaturePreset.self, from: json).challengeRating)
    }

    func testRatingSurvivesSaveAndLoad() throws {
        let preset = CreaturePreset(name: "Bog Hulk", challengeRating: "1/2")
        let data = try JSONEncoder().encode(preset)
        XCTAssertEqual(try JSONDecoder().decode(CreaturePreset.self, from: data).challengeRating, "1/2")
    }
}
