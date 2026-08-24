import XCTest
@testable import initiative

/// The default roster is editorial data that gets typed by hand, so what's worth
/// testing is the kind of mistake typing makes: a duplicate, a typo'd creature
/// name in an encounter, a stat that can't be right.
final class DefaultContentTests: XCTestCase {

    // MARK: - Creatures

    func testCreatureNamesAreUnique() {
        let names = DefaultContent.creatures.map { $0.name.lowercased() }
        XCTAssertEqual(Set(names).count, names.count, "Two default creatures share a name; installing them would collide")
    }

    func testEveryCreatureHasPlausibleStats() {
        for creature in DefaultContent.creatures {
            XCTAssertFalse(creature.name.trimmingCharacters(in: .whitespaces).isEmpty)
            XCTAssertGreaterThan(creature.maxHP, 0, "\(creature.name) has no hit points")
            XCTAssertGreaterThan(creature.armorClass, 0, "\(creature.name) has no armor class")
            // Wide, but wide enough to catch a slipped digit — an AC of 180 or an
            // initiative bonus of 15 is a typo, not a design decision.
            XCTAssertLessThanOrEqual(creature.armorClass, 25, "\(creature.name)'s armor class looks like a typo")
            XCTAssertLessThanOrEqual(creature.maxHP, 500, "\(creature.name)'s hit points look like a typo")
            XCTAssertTrue((-5...8).contains(creature.initiativeBonus), "\(creature.name)'s initiative bonus looks like a typo")
        }
    }

    /// The roster is meant to span a session's worth of difficulty, not cluster
    /// at one end. Loose bounds — this is a smoke test against the list quietly
    /// becoming all low-level chaff.
    func testRosterSpansARangeOfThreatLevels() {
        let hp = DefaultContent.creatures.map(\.maxHP)
        XCTAssertLessThan(hp.min()!, 15, "nothing in the roster is weak enough to use as a minion")
        XCTAssertGreaterThan(hp.max()!, 150, "nothing in the roster is big enough to end a session on")
    }

    // MARK: - Encounters

    func testEncounterNamesAreUnique() {
        let names = DefaultContent.encounters.map { $0.name.lowercased() }
        XCTAssertEqual(Set(names).count, names.count, "Two default encounters share a name")
    }

    /// The reason encounters name creatures instead of restating stats: a typo
    /// here would otherwise install an encounter whose combatants have no HP or
    /// AC, and nothing at runtime would complain.
    func testEveryEncounterLineNamesARealCreature() {
        for template in DefaultContent.encounters {
            for line in template.lineup {
                XCTAssertNotNil(
                    DefaultContent.creature(named: line.creature),
                    "\(template.name) references \"\(line.creature)\", which isn't in the creature roster"
                )
            }
        }
    }

    func testEveryEncounterResolvesToCompleteEntries() {
        for template in DefaultContent.encounters {
            let encounter = DefaultContent.encounter(from: template)
            XCTAssertEqual(
                encounter.entries.count, template.lineup.count,
                "\(template.name) lost a line when resolved — a creature name didn't match"
            )
            for entry in encounter.entries {
                XCTAssertNotNil(entry.maxHP, "\(template.name): \(entry.name) resolved without hit points")
                XCTAssertNotNil(entry.armorClass, "\(template.name): \(entry.name) resolved without an armor class")
                XCTAssertGreaterThanOrEqual(entry.count, 1)
            }
        }
    }

    /// Every encounter should be worth starting: a single creature with no
    /// support is something you'd add by hand rather than prepare in advance.
    func testEveryEncounterHasSomethingToTrack() {
        for template in DefaultContent.encounters {
            let total = template.lineup.reduce(0) { $0 + $1.count }
            XCTAssertGreaterThanOrEqual(total, 2, "\(template.name) is a single combatant")
        }
    }
}
