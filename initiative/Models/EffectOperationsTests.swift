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

/// "Until the end of their next turn" means the next turn they start: when the
/// effect goes on during its owner's own turn, the end of that turn doesn't count.
final class OwnTurnCountdownTests: XCTestCase {

    private func session() -> CombatSession {
        let session = CombatSession()
        session.addCombatant(name: "Alpha", initiative: 20)
        session.addCombatant(name: "Beta", initiative: 10)
        return session
    }

    private func has(_ session: CombatSession, _ name: String, _ effect: Effect) -> Bool {
        session.combatants.first { $0.name == name }!.effects.contains { $0.id == effect.id }
    }

    func testAppliedOnOwnTurnLastsThroughTheirNextTurn() {
        let session = session()
        let dodge = Effect(name: "Dodging", durationType: .untilEndOfTheirTurn(remainingTurns: 1))
        session.addEffect(dodge, to: session.combatants[0].id) // Alpha's own turn
        session.nextTurn() // Alpha's turn ends: it doesn't count
        XCTAssertTrue(has(session, "Alpha", dodge))
        session.nextTurn() // Alpha's next turn starts
        XCTAssertTrue(has(session, "Alpha", dodge))
        session.nextTurn() // and ends
        XCTAssertFalse(has(session, "Alpha", dodge))
    }

    func testAppliedOnSomeoneElsesTurnEndsAtTheEndOfTheirNextTurn() {
        let session = session()
        let blind = Effect(name: "Blinded", durationType: .untilEndOfTheirTurn(remainingTurns: 1))
        session.addEffect(blind, to: session.combatants[1].id) // on Alpha's turn
        session.nextTurn() // Beta's turn starts
        XCTAssertTrue(has(session, "Beta", blind))
        session.nextTurn() // and ends
        XCTAssertFalse(has(session, "Beta", blind))
    }

    /// Several turns count the same way: the turn in progress is not one of them.
    func testCountsOnlyTurnsAfterTheOneInProgress() {
        let session = session()
        let haste = Effect(name: "Hasted", durationType: .untilEndOfTheirTurn(remainingTurns: 2))
        session.addEffect(haste, to: session.combatants[0].id)
        for _ in 0..<4 { session.nextTurn() } // ends Alpha's own, next and Beta's twice
        XCTAssertTrue(has(session, "Alpha", haste))
        session.nextTurn() // end of Alpha's second turn after this one
        XCTAssertFalse(has(session, "Alpha", haste))
    }

    func testTheMarkRoundTrips() throws {
        let session = session()
        session.addEffect(Effect(name: "Dodging", durationType: .untilEndOfTheirTurn(remainingTurns: 1)), to: session.combatants[0].id)
        let data = try JSONEncoder().encode(session.makeRecord())
        let loaded = CombatSession()
        loaded.load(try JSONDecoder().decode(SessionRecord.self, from: data))
        loaded.nextTurn()
        XCTAssertEqual(loaded.combatants[0].effects.count, 1)
    }
}
