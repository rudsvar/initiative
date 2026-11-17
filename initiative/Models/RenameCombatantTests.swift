import XCTest
@testable import initiative

/// A combatant's name follows the same rule as the session's: trimmed, never blank.
final class RenameCombatantTests: XCTestCase {

    func testANameIsTrimmedAndABlankOneIsRefused() {
        let session = CombatSession()
        session.addCombatant(name: "Goblin", initiative: 10)
        let id = session.combatants[0].id

        session.renameCombatant(id, to: "  ")
        XCTAssertEqual(session.combatants[0].name, "Goblin")

        session.renameCombatant(id, to: " Gob ")
        XCTAssertEqual(session.combatants[0].name, "Gob")
    }
}
