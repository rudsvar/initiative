import XCTest
@testable import initiative

/// The stat facts under a creature's name. Initiative has its own card, so it is not here.
final class StatFactsTests: XCTestCase {

    private func wolf() throws -> StatBlock {
        let combat = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let url = combat.deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Data/srd-creatures.json")
        let blocks = try SRDCatalog.load(from: url)
        return try XCTUnwrap(blocks.first { $0.name == "Wolf" })
    }

    func testInitiativeIsNotRepeatedInTheStats() throws {
        let facts = StatFacts.facts(for: try wolf())
        XCTAssertFalse(facts.contains { $0.0 == "Initiative" })
    }

    func testTheWolfHasItsSpeedAndChallengeToo() throws {
        let facts = StatFacts.facts(for: try wolf())
        XCTAssertTrue(facts.contains { $0.0 == "Speed" && $0.1 == "40 ft." })
        XCTAssertTrue(facts.contains { $0.0 == "CR" })
    }
}
