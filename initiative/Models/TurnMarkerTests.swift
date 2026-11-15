import XCTest
@testable import initiative

/// The roster's current-turn marker. While a start-of-turn prompt is open the
/// marker moves to the combatant whose turn is about to start; cancelling the
/// prompt leaves the turn, and so the marker, where it was.
final class TurnMarkerTests: XCTestCase {

    private func session() -> CombatSession {
        let session = CombatSession()
        session.addCombatant(name: "Alpha", initiative: 20, maxHP: 10)
        session.addCombatant(name: "Wren", initiative: 10, maxHP: 10, isPlayer: true)
        return session
    }

    private func id(_ session: CombatSession, _ name: String) -> UUID {
        session.combatants.first { $0.name == name }!.id
    }

    /// Without a prompt the marker is simply whoever's turn it is.
    func testWithoutPromptsTheMarkerIsTheCurrentCombatant() {
        let session = session()
        XCTAssertEqual(session.highlightedCombatantID(awaitingPrompts: false), id(session, "Alpha"))
    }

    /// Wren is dying, so her start-of-turn death save is owed. While it is open
    /// the marker is on Wren, the combatant about to act.
    func testWhileAStartOfTurnPromptIsOpenTheMarkerMovesToTheNextCombatant() {
        let session = session()
        session.combatants[1].deathSaves = DeathSaves()
        XCTAssertFalse(session.pendingTurnPrompts().isEmpty)
        XCTAssertEqual(session.highlightedCombatantID(awaitingPrompts: true), id(session, "Wren"))
    }

    /// Cancelling is not a turn change: once the prompt is closed the marker is
    /// back on the combatant whose turn it still is.
    func testCancellingThePromptLeavesTheMarkerWhereItWas() {
        let session = session()
        session.combatants[1].deathSaves = DeathSaves()
        XCTAssertEqual(session.highlightedCombatantID(awaitingPrompts: false), id(session, "Alpha"))
        XCTAssertEqual(session.currentCombatant?.name, "Alpha")
    }

    /// The marker skips the dead, the same as the turn does.
    func testTheUpcomingMarkerSkipsDeadCombatants() {
        let session = CombatSession()
        session.addCombatant(name: "Alpha", initiative: 20, maxHP: 10)
        session.addCombatant(name: "Gamma", initiative: 15, maxHP: 10)
        session.addCombatant(name: "Wren", initiative: 10, maxHP: 10, isPlayer: true)
        _ = session.applyDamage(to: id(session, "Gamma"), amount: 10)
        session.combatants[2].deathSaves = DeathSaves()
        XCTAssertEqual(session.highlightedCombatantID(awaitingPrompts: true), id(session, "Wren"))
    }
}
