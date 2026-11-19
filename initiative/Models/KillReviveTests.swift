import XCTest
@testable import initiative

/// Kill, revive and remove: Kill and Revive work with or without HP tracked, and all
/// three can be undone with Previous.
final class KillReviveTests: XCTestCase {

    private func session() -> CombatSession {
        let session = CombatSession()
        session.addCombatant(name: "Alpha", initiative: 20, maxHP: 7)
        session.addCombatant(name: "Gamma", initiative: 10)
        return session
    }

    private func index(_ session: CombatSession, _ name: String) -> Int {
        session.combatants.firstIndex { $0.name == name }!
    }

    func testKillWithoutHPMarksDeadAndReviveClearsIt() {
        let session = session()
        let gamma = session.combatants[index(session, "Gamma")].id
        session.kill(gamma)
        XCTAssertTrue(session.combatants[index(session, "Gamma")].isDead)
        session.revive(gamma)
        XCTAssertFalse(session.combatants[index(session, "Gamma")].isDead)
    }

    func testKillWithHPSetsItToZeroAndReviveBringsItBackToOne() {
        let session = session()
        let alpha = session.combatants[index(session, "Alpha")].id
        session.kill(alpha)
        XCTAssertEqual(session.combatants[index(session, "Alpha")].currentHP, 0)
        XCTAssertTrue(session.combatants[index(session, "Alpha")].isDead)
        session.revive(alpha)
        XCTAssertEqual(session.combatants[index(session, "Alpha")].currentHP, 1)
        XCTAssertFalse(session.combatants[index(session, "Alpha")].isDead)
    }

    func testPreviousUndoesAKill() {
        let session = session()
        let gamma = session.combatants[index(session, "Gamma")].id
        session.kill(gamma)
        session.previousTurn()
        XCTAssertFalse(session.combatants[index(session, "Gamma")].isDead)
    }

    func testPreviousUndoesARemove() {
        let session = session()
        let gamma = session.combatants[index(session, "Gamma")].id
        session.removeCombatant(id: gamma)
        XCTAssertNil(session.combatants.first { $0.name == "Gamma" })
        session.previousTurn()
        XCTAssertNotNil(session.combatants.first { $0.name == "Gamma" })
    }

    func testMarkedDeadDecodesAsNilFromOlderSaves() throws {
        let json = """
        {"id":"\(UUID().uuidString)","name":"Gamma","initiative":10,"effects":[]}
        """.data(using: .utf8)!
        let combatant = try JSONDecoder().decode(Combatant.self, from: json)
        XCTAssertNil(combatant.markedDead)
        XCTAssertFalse(combatant.isDead)
    }

    /// Dropping to 0 by damage ends concentration; Kill must too.
    func testKillEndsConcentration() {
        let session = session()
        let alpha = session.combatants[index(session, "Alpha")].id
        session.toggleConcentration(for: alpha)
        session.kill(alpha)
        XCTAssertFalse(session.combatants[index(session, "Alpha")].isConcentrating)
    }

    /// Max HP lowered to 0 kills. Revive brings max back to 1 along with current,
    /// never 1/0 HP, and a replay after a deleted entry agrees.
    func testReviveAfterMaxHPLoweredToZero() {
        let session = session()
        let alpha = session.combatants[index(session, "Alpha")].id
        session.applyDamage(to: alpha, amount: 2)
        let damage = session.log.last!.id
        session.decreaseMaxHP(for: alpha, amount: 7)
        session.revive(alpha)
        var revived = session.combatants[index(session, "Alpha")]
        XCTAssertEqual(revived.currentHP, 1)
        XCTAssertEqual(revived.maxHP, 1)
        XCTAssertFalse(revived.isDead)

        session.deleteLogEntry(damage)
        revived = session.combatants[index(session, "Alpha")]
        XCTAssertEqual(revived.currentHP, 1)
        XCTAssertEqual(revived.maxHP, 1)
    }
}
