import XCTest
@testable import initiative

final class TemporaryHPTests: XCTestCase {

    private func session() -> (CombatSession, UUID) {
        let session = CombatSession()
        session.addCombatant(name: "Wren", initiative: 20, maxHP: 30, isPlayer: true)
        return (session, session.combatants[0].id)
    }

    // MARK: - Absorption

    func testDamageComesOffTheBufferFirst() {
        let (session, id) = session()
        session.grantTemporaryHP(to: id, amount: 8)

        session.applyDamage(to: id, amount: 5)

        XCTAssertEqual(session.combatants[0].temporaryHP, 3)
        XCTAssertEqual(session.combatants[0].currentHP, 30, "real hit points shouldn't move while the buffer covers it")
    }

    func testDamageBeyondTheBufferSpillsIntoRealHitPoints() {
        let (session, id) = session()
        session.grantTemporaryHP(to: id, amount: 8)

        session.applyDamage(to: id, amount: 12)

        XCTAssertNil(session.combatants[0].temporaryHP, "a spent buffer is gone, not zero")
        XCTAssertEqual(session.combatants[0].currentHP, 26)
    }

    func testAnExactlySpentBufferIsCleared() {
        let (session, id) = session()
        session.grantTemporaryHP(to: id, amount: 8)

        session.applyDamage(to: id, amount: 8)

        XCTAssertNil(session.combatants[0].temporaryHP)
        XCTAssertEqual(session.combatants[0].currentHP, 30)
    }

    /// It's a buffer, not hit points: healing tops up real HP and leaves it alone.
    func testHealingDoesNotRefillTheBuffer() {
        let (session, id) = session()
        session.grantTemporaryHP(to: id, amount: 8)
        session.applyDamage(to: id, amount: 20)

        session.applyHealing(to: id, amount: 10)

        XCTAssertNil(session.combatants[0].temporaryHP)
        XCTAssertEqual(session.combatants[0].currentHP, 28)
    }

    /// Replace rather than add: two sources don't stack, and "replace" is what a
    /// DM can predict without the app having a rule about which is larger.
    func testGrantingAgainReplacesRatherThanStacks() {
        let (session, id) = session()
        session.grantTemporaryHP(to: id, amount: 8)

        session.grantTemporaryHP(to: id, amount: 5)

        XCTAssertEqual(session.combatants[0].temporaryHP, 5)
    }

    func testABufferCanSaveSomeoneFromDying() {
        let (session, id) = session()
        session.grantTemporaryHP(to: id, amount: 40)

        session.applyDamage(to: id, amount: 35)

        XCTAssertEqual(session.combatants[0].currentHP, 30)
        XCTAssertFalse(session.combatants[0].isDying)
    }

    // MARK: - Replay

    /// The live path and the replay path have to agree exactly, or deleting a log
    /// entry recomputes a different answer than the DM originally saw. They share
    /// one function; this is the test that says so.
    func testDeletingADamageEntryReplaysTheBufferCorrectly() {
        let (session, id) = session()
        session.grantTemporaryHP(to: id, amount: 8)
        session.applyDamage(to: id, amount: 5)
        session.applyDamage(to: id, amount: 10)
        XCTAssertEqual(session.combatants[0].currentHP, 23)

        // Undo the first hit: the buffer should now absorb 8 of the second.
        let firstHit = session.log.first { $0.hpOperation == .damage(amount: 5) }!
        session.deleteLogEntry(firstHit.id)

        XCTAssertNil(session.combatants[0].temporaryHP)
        XCTAssertEqual(session.combatants[0].currentHP, 28)
    }

    func testDeletingTheGrantReplaysWithoutTheBuffer() {
        let (session, id) = session()
        session.grantTemporaryHP(to: id, amount: 8)
        session.applyDamage(to: id, amount: 5)

        let grant = session.log.first { $0.hpOperation == .grantTemporaryHP(amount: 8) }!
        session.deleteLogEntry(grant.id)

        XCTAssertNil(session.combatants[0].temporaryHP)
        XCTAssertEqual(session.combatants[0].currentHP, 25, "without the buffer the hit should have landed in full")
    }

    // MARK: - Arithmetic

    func testAbsorbHandlesNoBuffer() {
        let result = CombatSession.absorb(damage: 5, temporaryHP: nil, currentHP: 10)
        XCTAssertNil(result.temporaryHP)
        XCTAssertEqual(result.currentHP, 5)
    }

    func testAbsorbNeverDrivesHitPointsNegative() {
        let result = CombatSession.absorb(damage: 100, temporaryHP: 3, currentHP: 10)
        XCTAssertNil(result.temporaryHP)
        XCTAssertEqual(result.currentHP, 0)
    }
}
