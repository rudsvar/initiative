import XCTest
@testable import initiative

final class SRDCatalogTests: XCTestCase {

    /// The JSON in the repo, read straight from disk so the test does not depend
    /// on how the test bundle is hosted.
    private func repoStatBlocks() throws -> [StatBlock] {
        let stores = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let url = stores.deletingLastPathComponent().appendingPathComponent("Data/srd-creatures.json")
        return try SRDCatalog.load(from: url)
    }

    func testLookupByNameFindsTheSameBlockAsAScan() {
        for block in SRDCatalog.bundled {
            XCTAssertEqual(SRDCatalog.block(named: block.name)?.challenge.cr, block.challenge.cr, block.name)
        }
        XCTAssertNil(SRDCatalog.block(named: "Not A Creature"))
    }

    /// Copies spawned together are numbered ("Wolf 2"); each is still a Wolf.
    func testANumberedCopyFindsItsCreaturesBlock() {
        XCTAssertEqual(SRDCatalog.block(forCombatantNamed: "Wolf")?.name, "Wolf")
        XCTAssertEqual(SRDCatalog.block(forCombatantNamed: "Wolf 2")?.name, "Wolf")
        XCTAssertEqual(SRDCatalog.block(forCombatantNamed: "Wolf 12")?.name, "Wolf")
        XCTAssertNil(SRDCatalog.block(forCombatantNamed: "Wolfgang 2"))
        XCTAssertNil(SRDCatalog.block(forCombatantNamed: "2"))
    }

    func testFileLoadsWithTheExpectedCreatures() throws {
        let names = try repoStatBlocks().map(\.name)
        XCTAssertEqual(names.count, 323)
        XCTAssertTrue(names.contains("Wolf"))
    }

    func testWolfStatBlockKeepsItsPrintedDetails() throws {
        let wolf = try XCTUnwrap(repoStatBlocks().first { $0.name == "Wolf" })
        XCTAssertEqual(wolf.armorClass, 12)
        XCTAssertEqual(wolf.initiative, StatBlock.Initiative(modifier: 2, score: 12))
        XCTAssertEqual(wolf.hitPoints, StatBlock.HitPoints(average: 11, formula: "2d8 + 2"))
        XCTAssertEqual(wolf.abilities.dex.score, 15)
        XCTAssertEqual(wolf.abilities.int.modifier, -4)
        XCTAssertEqual(wolf.challenge.cr, "1/4")
        XCTAssertEqual(wolf.actions.first?.name, "Bite")
        XCTAssertNil(wolf.gear)
    }

    /// The built-in creatures carry three numbers each. Where one of them comes
    /// from the SRD, those numbers must match the stat block exactly.
    func testBuiltInSRDCreaturesMatchTheirStatBlocks() throws {
        let blocks = try repoStatBlocks()
        var matched = 0
        for creature in DefaultContent.creatures {
            guard let block = blocks.first(where: { $0.name == creature.name }) else { continue }
            matched += 1
            XCTAssertEqual(creature.maxHP, block.hitPoints.average, creature.name)
            XCTAssertEqual(creature.armorClass, block.armorClass, creature.name)
            XCTAssertEqual(creature.initiativeBonus, block.initiative.modifier, creature.name)
        }
        XCTAssertEqual(matched, DefaultContent.creatures.count, "Every built-in creature has a stat block in the file")
    }
}
