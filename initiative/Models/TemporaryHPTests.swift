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

    /// Two grants never stack: the larger one stays (the rules let you choose).
    func testGrantingAgainKeepsTheLargerRatherThanStacking() {
        let (session, id) = session()
        session.grantTemporaryHP(to: id, amount: 8)

        session.grantTemporaryHP(to: id, amount: 5)
        XCTAssertEqual(session.combatants[0].temporaryHP, 8)

        session.grantTemporaryHP(to: id, amount: 12)
        XCTAssertEqual(session.combatants[0].temporaryHP, 12)
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

/// Hit point rules as written: temporary HP, massive damage, damage at 0 HP,
/// and max HP reduced to 0.
final class RulesAsWrittenTests: XCTestCase {

    private func player(maxHP: Int = 20) -> (CombatSession, UUID) {
        let session = CombatSession()
        session.addCombatant(name: "Wren", initiative: 20, maxHP: maxHP, isPlayer: true)
        return (session, session.combatants[0].id)
    }

    func testMassiveDamageKillsAPlayerOutright() {
        let (session, id) = player(maxHP: 20)
        session.applyDamage(to: id, amount: 5) // 15 HP left

        session.applyDamage(to: id, amount: 35) // 20 past zero, equal to max HP

        XCTAssertTrue(session.combatants[0].isDead)
    }

    func testJustUnderMassiveDamageOnlyStartsDying() {
        let (session, id) = player(maxHP: 20)
        session.applyDamage(to: id, amount: 5)

        session.applyDamage(to: id, amount: 34) // 19 past zero

        XCTAssertTrue(session.combatants[0].isDying)
        XCTAssertFalse(session.combatants[0].isDead)
    }

    func testTemporaryHPCountsTowardNothingForMassiveDamage() {
        let (session, id) = player(maxHP: 20)
        session.grantTemporaryHP(to: id, amount: 10)

        session.applyDamage(to: id, amount: 39) // 10 absorbed, 29 to HP, 9 past zero

        XCTAssertFalse(session.combatants[0].isDead)
    }

    func testDamageAtZeroIsAFailedDeathSave() {
        let (session, id) = player()
        session.applyDamage(to: id, amount: 20)
        XCTAssertEqual(session.combatants[0].deathSaves?.failures, 0)

        session.applyDamage(to: id, amount: 3)

        XCTAssertEqual(session.combatants[0].deathSaves?.failures, 1)
    }

    func testDamageBreaksStability() {
        let (session, id) = player()
        session.applyDamage(to: id, amount: 20)
        session.combatants[0].deathSaves = DeathSaves(successes: 3, failures: 1)

        session.applyDamage(to: id, amount: 2)

        XCTAssertEqual(session.combatants[0].deathSaves, DeathSaves(successes: 0, failures: 1))
    }

    func testMaxHPCanBeReducedToZeroWhichKills() {
        let (session, id) = player(maxHP: 20)

        session.decreaseMaxHP(for: id, amount: 25)

        XCTAssertEqual(session.combatants[0].maxHP, 0)
        XCTAssertTrue(session.combatants[0].isDead)
    }

    func testReducingMaxHPSurvivesReplay() {
        let (session, id) = player(maxHP: 30)
        session.applyDamage(to: id, amount: 4)
        session.decreaseMaxHP(for: id, amount: 10) // 20 max, 20 current
        let damage = session.log.first { $0.hpOperation == .damage(amount: 4) }!

        session.deleteLogEntry(damage.id)

        XCTAssertEqual(session.combatants[0].maxHP, 20)
        XCTAssertEqual(session.combatants[0].currentHP, 20)
    }

    func testNewTemporaryHPNeverLowersTheBufferAfterReplay() {
        let (session, id) = player()
        session.grantTemporaryHP(to: id, amount: 8)
        session.grantTemporaryHP(to: id, amount: 5)
        session.applyDamage(to: id, amount: 1)
        let damage = session.log.first { $0.hpOperation == .damage(amount: 1) }!

        session.deleteLogEntry(damage.id)

        XCTAssertEqual(session.combatants[0].temporaryHP, 8)
    }
}
