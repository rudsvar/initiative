import XCTest
@testable import initiative

/// Changing a combatant's initiative mid-fight moves them in the turn order, and the
/// turn that is in progress stays with whoever has it.
final class InitiativeEditTests: XCTestCase {

    private func session() -> CombatSession {
        let session = CombatSession()
        session.addCombatant(name: "Alpha", initiative: 20)
        session.addCombatant(name: "Bravo", initiative: 15)
        session.addCombatant(name: "Charlie", initiative: 10)
        return session
    }

    private func id(_ session: CombatSession, _ name: String) -> UUID {
        session.combatants.first { $0.name == name }!.id
    }

    func testTurnOrderFollowsTheNewInitiative() {
        let session = session()
        // Charlie now goes first; Alpha's turn is in progress.
        session.setInitiative(25, for: id(session, "Charlie"))
        XCTAssertEqual(session.combatants.map(\.name), ["Charlie", "Alpha", "Bravo"])
        XCTAssertEqual(session.currentCombatant?.name, "Alpha")
        session.nextTurn()
        XCTAssertEqual(session.currentCombatant?.name, "Bravo")
        session.nextTurn()
        // Charlie is first in the order now, so reaching them starts a new round.
        XCTAssertEqual(session.currentCombatant?.name, "Charlie")
        XCTAssertEqual(session.roundNumber, 2)
    }

    func testTheCurrentCombatantCanMoveWithoutLosingTheTurn() {
        let session = session()
        session.setInitiative(5, for: id(session, "Alpha"))
        XCTAssertEqual(session.currentCombatant?.name, "Alpha")
        // Alpha is last now, so the next turn wraps to a new round.
        session.nextTurn()
        XCTAssertEqual(session.currentCombatant?.name, "Bravo")
        XCTAssertEqual(session.roundNumber, 2)
    }

    func testTheChangeIsLogged() {
        let session = session()
        session.setInitiative(25, for: id(session, "Charlie"))
        XCTAssertEqual(session.log.last?.text, "Charlie's initiative changed to 25")
    }

    // MARK: - Adding a combatant mid-fight

    func testAddingACombatantMidFightKeepsTheTurn() {
        let session = session()
        session.nextTurn() // Bravo
        session.addCombatant(name: "Scout", initiative: 18)
        XCTAssertEqual(session.combatants.map(\.name), ["Alpha", "Scout", "Bravo", "Charlie"])
        XCTAssertEqual(session.currentCombatant?.name, "Bravo")
        session.nextTurn()
        XCTAssertEqual(session.currentCombatant?.name, "Charlie")
    }

    func testAddingSeveralMidFightKeepsTheTurnInALaterRound() {
        let session = session()
        session.nextTurn(); session.nextTurn(); session.nextTurn() // Alpha, round 2
        session.addCombatants(name: "Wolf", initiative: 25, maxHP: 11, count: 2)
        XCTAssertEqual(session.currentCombatant?.name, "Alpha")
        XCTAssertEqual(session.roundNumber, 2)
    }

    /// Before anyone has acted the roster is still being built (an encounter adds
    /// its creatures one group at a time), so the top of the order goes first.
    func testBeforeTheFightBeginsTheTopOfTheOrderGoesFirst() {
        let session = session()
        session.addCombatant(name: "Scout", initiative: 25)
        XCTAssertEqual(session.currentCombatant?.name, "Scout")
    }
}
