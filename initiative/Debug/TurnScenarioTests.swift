#if DEBUG
import XCTest
@testable import initiative

/// The steps each turn scenario tells the owner to take on the phone, run here.
final class TurnScenarioTests: XCTestCase {

    private func current(_ session: CombatSession) -> String? { session.currentCombatant?.name }

    func testLateArrivalWaitsForTheirPlace() {
        let session = TestCombats.lateArrivalWaitsForTheirPlace()
        session.addCombatant(name: "Scout", initiative: 18)
        XCTAssertEqual(session.combatants.map(\.name), ["Alpha", "Scout", "Beta", "Gamma"])
        XCTAssertEqual(current(session), "Beta")
    }

    func testLastFailedSaveKeepsTheTurn() {
        let session = TestCombats.lastFailedSaveKeepsTheTurn()
        let save = session.pendingTurnPrompts().first { $0.subject == .deathSave }!
        session.nextTurn(resolving: [save: .failure])
        XCTAssertEqual(current(session), "Wren")
        XCTAssertTrue(session.currentCombatant!.isDead)
        XCTAssertEqual(session.pendingTurnPrompts().map(\.combatantName), ["Omega"])
    }

    func testDodgeLastsThroughTheirNextTurn() {
        let session = TestCombats.dodgeLastsThroughTheirNextTurn()
        session.nextTurn(); session.nextTurn()
        XCTAssertEqual(current(session), "Alpha")
        XCTAssertEqual(session.combatants[0].visibleEffects.map(\.name), ["Dodging"])
        session.nextTurn()
        XCTAssertTrue(session.combatants[0].visibleEffects.isEmpty)
    }
}
#endif
