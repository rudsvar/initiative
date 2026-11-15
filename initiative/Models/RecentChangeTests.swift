import XCTest
@testable import initiative

/// The change beside current HP and AC: the net change since the combatant's own
/// turn last started. Max HP and AC edits go through the same tracking.
final class RecentChangeTests: XCTestCase {

    private func alpha(_ session: CombatSession) -> Int {
        session.combatants.firstIndex { $0.name == "Alpha" }!
    }

    private func omega(_ session: CombatSession) -> Int {
        session.combatants.firstIndex { $0.name == "Omega" }!
    }

    func testDamageAndHealingNetOut() {
        let session = TestCombats.hpAndACChangesShowUntilTurnStarts()
        let id = session.combatants[alpha(session)].id
        _ = session.applyDamage(to: id, amount: 4)
        session.applyHealing(to: id, amount: 2)
        XCTAssertEqual(session.combatants[alpha(session)].recentHPChange, -2)
    }

    func testChangeClearsWhenTheCombatantsTurnStarts() {
        let session = TestCombats.hpAndACChangesShowUntilTurnStarts()
        let id = session.combatants[omega(session)].id
        _ = session.applyDamage(to: id, amount: 4)
        XCTAssertEqual(session.combatants[omega(session)].recentHPChange, -4, "shown before Omega's turn")
        session.nextTurn()
        XCTAssertNil(session.combatants[omega(session)].recentHPChange, "cleared when Omega's turn starts")
    }

    func testLoweringMaxHPClampsCurrentAndRecordsTheDrop() {
        let session = TestCombats.hpAndACChangesShowUntilTurnStarts()
        let id = session.combatants[alpha(session)].id
        _ = session.applyDamage(to: id, amount: 5)
        session.decreaseMaxHP(for: id, amount: 10)
        XCTAssertEqual(session.combatants[alpha(session)].maxHP, 10)
        XCTAssertEqual(session.combatants[alpha(session)].currentHP, 10)
        XCTAssertEqual(session.combatants[alpha(session)].recentHPChange, -10)
    }

    func testArmorClassChangesNetOutAndNeverGoBelowZero() {
        let session = TestCombats.hpAndACChangesShowUntilTurnStarts()
        let id = session.combatants[alpha(session)].id
        session.adjustArmorClass(for: id, by: -2)
        session.adjustArmorClass(for: id, by: 5)
        XCTAssertEqual(session.combatants[alpha(session)].armorClass, 17)
        XCTAssertEqual(session.combatants[alpha(session)].recentACChange, 3)
        session.adjustArmorClass(for: id, by: -100)
        XCTAssertEqual(session.combatants[alpha(session)].armorClass, 0)
    }
}
