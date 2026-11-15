import XCTest
@testable import initiative

/// The turn passes over the dead: a creature at 0 HP, or a character whose death
/// saves failed. A dying character (still rolling) keeps its turns.
final class DeadCombatantTurnTests: XCTestCase {

    private func name(_ session: CombatSession) -> String {
        session.combatants[session.currentTurnIndex].name
    }

    func testDeadCreatureIsSkipped() {
        let session = TestCombats.deadCreatureIsSkipped()
        session.nextTurn()
        XCTAssertEqual(name(session), "Omega")
    }

    func testFailedDeathSavesAreSkipped() {
        let session = TestCombats.failedDeathSavesAreSkipped()
        session.nextTurn()
        XCTAssertEqual(name(session), "Omega")
    }

    func testDyingCharacterKeepsItsTurns() {
        let session = TestCombats.dyingCharacterKeepsItsTurns()
        session.nextTurn()
        XCTAssertEqual(name(session), "Wren")
    }

    func testLastStandingKeepsTheTurnAndTheRoundStillAdvances() {
        let session = TestCombats.lastStandingKeepsTheTurn()
        session.nextTurn()
        XCTAssertEqual(name(session), "Alpha")
        XCTAssertEqual(session.roundNumber, 2)
    }

    func testSkippingPastTheEndStartsANewRound() {
        let session = TestCombats.deadCreatureIsSkipped()
        session.currentTurnIndex = 2
        session.nextTurn()
        XCTAssertEqual(name(session), "Alpha")
        XCTAssertEqual(session.roundNumber, 2)
    }
}
