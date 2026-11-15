import XCTest
@testable import initiative

/// The stat facts under a creature's name: the initiative bonus, then the rest.
final class StatFactsTests: XCTestCase {

    private func wolf() throws -> StatBlock {
        let combat = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let url = combat.deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Data/srd-creatures.json")
        let blocks = try SRDCatalog.load(from: url)
        return try XCTUnwrap(blocks.first { $0.name == "Wolf" })
    }

    func testInitiativeBonusIsTheModifierOnly() throws {
        let facts = StatFacts.facts(for: try wolf())
        XCTAssertEqual(facts.first?.0, "Initiative bonus")
        XCTAssertEqual(facts.first?.1, "+2")
    }

    func testTheWolfHasItsSpeedAndChallengeToo() throws {
        let facts = StatFacts.facts(for: try wolf())
        XCTAssertTrue(facts.contains { $0.0 == "Speed" && $0.1 == "40 ft." })
        XCTAssertTrue(facts.contains { $0.0 == "CR" })
    }
}
