import XCTest
@testable import initiative

/// Deleting a log entry replays the combatant's HP from the log. Every change to
/// HP has to be part of that replay, or deleting an unrelated entry quietly undoes it.
final class HPReplayTests: XCTestCase {

    private func session(isPlayer: Bool = false) -> (CombatSession, UUID) {
        let session = CombatSession()
        session.addCombatant(name: "Alpha", initiative: 20, maxHP: 10, isPlayer: isPlayer)
        return (session, session.combatants[0].id)
    }

    private func alpha(_ session: CombatSession) -> Combatant { session.combatants[0] }

    /// The most recent deletable entry, the one each test removes.
    private func deleteLastDeletable(_ session: CombatSession) {
        session.deleteLogEntry(session.log.last { $0.isDeletable }!.id)
    }

    func testHealAboveMaxSurvivesDeletingAnEarlierEntry() {
        let (session, id) = session()
        session.applyDamage(to: id, amount: 2)
        let damage = session.log.last!.id
        session.heal(id, amount: 5, goAboveMax: true)
        session.deleteLogEntry(damage)
        XCTAssertEqual(alpha(session).currentHP, 10)
        XCTAssertEqual(alpha(session).temporaryHP, 5)
    }

    /// Temporary HP doesn't stack, so a heal above max keeps a larger buffer that
    /// is already there, as a grant does, and the replay agrees.
    func testHealAboveMaxKeepsALargerBuffer() {
        let (session, id) = session()
        session.applyDamage(to: id, amount: 2)
        let damage = session.log.last!.id
        session.grantTemporaryHP(to: id, amount: 6)
        session.heal(id, amount: 4, goAboveMax: true) // 2 over max
        XCTAssertEqual(alpha(session).currentHP, 10)
        XCTAssertEqual(alpha(session).temporaryHP, 6)
        XCTAssertEqual(session.log.last?.text, "Alpha healed 4 HP and kept 6 temporary HP instead of 2 (10/10 HP)")
        session.deleteLogEntry(damage) // now 4 over max, still less than 6
        XCTAssertEqual(alpha(session).temporaryHP, 6)
    }

    func testLoweredMaxHPSurvivesDeletingAnEarlierEntry() {
        let (session, id) = session()
        session.applyDamage(to: id, amount: 2)
        let damage = session.log.last!.id
        session.decreaseMaxHP(for: id, amount: 3)
        session.deleteLogEntry(damage)
        XCTAssertEqual(alpha(session).maxHP, 7)
        XCTAssertEqual(alpha(session).currentHP, 7)
    }

    func testKillSurvivesDeletingAnEarlierEntry() {
        let (session, id) = session()
        session.applyDamage(to: id, amount: 2)
        let damage = session.log.last!.id
        session.kill(id)
        session.deleteLogEntry(damage)
        XCTAssertEqual(alpha(session).currentHP, 0)
        XCTAssertTrue(alpha(session).isDead)
    }

    func testReviveSurvivesDeletingALaterEntry() {
        let (session, id) = session()
        session.applyDamage(to: id, amount: 10)
        session.revive(id)
        session.grantTemporaryHP(to: id, amount: 3)
        deleteLastDeletable(session)
        XCTAssertEqual(alpha(session).currentHP, 1)
        XCTAssertFalse(alpha(session).isDead)
    }

    func testNaturalTwentySurvivesDeletingALaterEntry() {
        let (session, id) = session(isPlayer: true)
        session.applyDamage(to: id, amount: 10)
        let save = TurnPrompt(id: id, combatantID: id, combatantName: "Alpha", subject: .deathSave, title: "Death save", hint: nil, deathSaves: alpha(session).deathSaves)
        session.resolvePrompt(save, outcome: .criticalSuccess)
        session.grantTemporaryHP(to: id, amount: 3)
        deleteLastDeletable(session)
        XCTAssertEqual(alpha(session).currentHP, 1)
        XCTAssertFalse(alpha(session).isDead)
    }
}
