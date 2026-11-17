import XCTest
@testable import initiative

/// Deleting a log entry and then pressing Previous: the turn is undone, and the
/// deletion stays done.
final class LogDeleteUndoTests: XCTestCase {

    private func session() -> (CombatSession, UUID) {
        let session = CombatSession()
        session.addCombatant(name: "Alpha", initiative: 20, maxHP: 10)
        session.addCombatant(name: "Bravo", initiative: 10)
        return (session, session.combatants[0].id)
    }

    func testPreviousLeavesTheLogAsItWasMinusTheDeletedEntry() {
        let (session, alpha) = session()
        session.applyDamage(to: alpha, amount: 2)
        let damage = session.log.last!
        let before = session.log.map(\.text).filter { $0 != damage.text }

        session.nextTurn()
        session.deleteLogEntry(damage.id)
        session.previousTurn()

        XCTAssertEqual(session.log.map(\.text), before)
    }

    func testPreviousKeepsTheHPTheDeletionRestored() {
        let (session, alpha) = session()
        session.applyDamage(to: alpha, amount: 2)
        let damage = session.log.last!.id

        session.nextTurn()
        session.deleteLogEntry(damage)
        XCTAssertEqual(session.combatants[0].currentHP, 10)
        session.previousTurn()

        XCTAssertEqual(session.combatants[0].currentHP, 10)
    }

    func testAnEntryLoggedAfterTheTurnIsStillUndone() {
        let (session, alpha) = session()
        session.nextTurn()
        session.applyDamage(to: alpha, amount: 2)
        session.deleteLogEntry(session.log.last!.id)
        session.applyDamage(to: alpha, amount: 3)
        session.previousTurn()

        XCTAssertEqual(session.combatants[0].currentHP, 10)
        XCTAssertFalse(session.log.contains { $0.text.contains("took") })
    }
}
