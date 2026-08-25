import XCTest
@testable import initiative

/// The session-level effect operations the Effects screen drives. They live on
/// `CombatSession` rather than in the view precisely so they can be checked here.
final class EffectOperationsTests: XCTestCase {

    private func session() -> (CombatSession, UUID) {
        let session = CombatSession()
        session.addCombatant(name: "Bog Hulk", initiative: 18, maxHP: 84)
        return (session, session.combatants[0].id)
    }

    func testAddingAnEffectLogsIt() {
        let (session, id) = session()

        session.addEffect(Effect(name: "Stunned", durationType: .untilRemoved), to: id)

        XCTAssertEqual(session.combatants[0].visibleEffects.count, 1)
        XCTAssertTrue(session.log.contains { $0.text.contains("Stunned") })
    }

    func testRemovingAnEffectLogsIt() {
        let (session, id) = session()
        session.addEffect(Effect(name: "Stunned", durationType: .untilRemoved), to: id)
        let effect = session.combatants[0].visibleEffects[0]

        session.removeEffect(effect.id, from: id)

        XCTAssertTrue(session.combatants[0].visibleEffects.isEmpty)
        XCTAssertTrue(session.log.contains { $0.text.contains("removed") })
    }

    /// Reconfiguring keeps the effect's identity, so the Effects screen doesn't
    /// read as removing one and adding another — and the chip doesn't flicker.
    func testUpdatingKeepsIdentity() {
        let (session, id) = session()
        session.addEffect(Effect(name: "Stunned", durationType: .untilRemoved), to: id)
        var effect = session.combatants[0].visibleEffects[0]
        let originalID = effect.id

        effect.durationType = .untilEndOfTheirTurn(remainingTurns: 3)
        session.updateEffect(effect, on: id)

        XCTAssertEqual(session.combatants[0].visibleEffects.count, 1)
        XCTAssertEqual(session.combatants[0].visibleEffects[0].id, originalID)
        XCTAssertEqual(session.combatants[0].visibleEffects[0].durationType, .untilEndOfTheirTurn(remainingTurns: 3))
    }

    /// What decides whether a condition chip reads as on or off.
    func testLookupByNameIsCaseInsensitive() {
        let (session, id) = session()
        session.addEffect(Effect(name: "Stunned", durationType: .untilRemoved), to: id)

        XCTAssertNotNil(session.effect(named: "stunned", on: id))
        XCTAssertNil(session.effect(named: "Prone", on: id))
    }

    /// The reaction marker is an internal effect; it must not light up a chip or
    /// appear in the Active list.
    func testTheReactionMarkerIsNotFoundByName() {
        let (session, id) = session()
        session.toggleReaction(for: id)

        XCTAssertTrue(session.combatants[0].visibleEffects.isEmpty)
        XCTAssertNil(session.effect(named: "Reaction Used", on: id))
    }

    /// One tap applies the shape that condition usually wants — the whole point
    /// of the grid.
    func testApplyingAConditionUsesItsDefaultDuration() {
        let (session, id) = session()
        let prone = ConditionLibrary.matching(name: "Prone")!

        session.addEffect(Effect(name: prone.name, durationType: prone.defaultDuration), to: id)

        XCTAssertEqual(session.combatants[0].visibleEffects[0].durationType, .untilRemoved)
    }
}
