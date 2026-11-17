import XCTest
@testable import initiative

/// Concentration is a bare flag on the combatant, not an `Effect` — no name, no
/// duration. What's worth testing is when the damage check appears, that it's
/// inverted from every other prompt, and that the DM can toggle it by hand.
final class ConcentrationTests: XCTestCase {

    private func session() -> (CombatSession, UUID) {
        let session = CombatSession()
        session.addCombatant(name: "Marchetta", initiative: 20, maxHP: 30, isPlayer: true)
        return (session, session.combatants[0].id)
    }

    func testToggleTurnsItOnAndOff() {
        let (session, id) = session()

        session.toggleConcentration(for: id)
        XCTAssertTrue(session.combatants[0].isConcentrating)

        session.toggleConcentration(for: id)
        XCTAssertFalse(session.combatants[0].isConcentrating)
    }

    func testDamageRaisesACheck() {
        let (session, id) = session()
        session.toggleConcentration(for: id)

        let prompt = session.applyDamage(to: id, amount: 7)

        XCTAssertNotNil(prompt)
        XCTAssertEqual(prompt?.title, "Roll to hold concentration")
        XCTAssertEqual(prompt?.hint, "Took 7 damage, DC 10")
    }

    func testDCIsHalfTheDamageWhenThatIsHigher() {
        XCTAssertEqual(CombatSession.concentrationDC(damage: 7), 10)
        XCTAssertEqual(CombatSession.concentrationDC(damage: 20), 10)
        XCTAssertEqual(CombatSession.concentrationDC(damage: 25), 12)
    }

    func testNoCheckWithoutConcentration() {
        let (session, id) = session()
        XCTAssertNil(session.applyDamage(to: id, amount: 7))
    }

    func testHealingRaisesNoCheck() {
        let (session, id) = session()
        session.toggleConcentration(for: id)
        session.applyDamage(to: id, amount: 5)

        session.applyHealing(to: id, amount: 5)

        XCTAssertTrue(session.combatants[0].isConcentrating)
    }

    /// Being dropped to 0 ends it outright — there's nothing to roll for, so
    /// asking would be a prompt whose answer can't matter.
    func testBeingDroppedToZeroEndsItWithoutAsking() {
        let (session, id) = session()
        session.toggleConcentration(for: id)

        let prompt = session.applyDamage(to: id, amount: 30)

        XCTAssertNil(prompt)
        XCTAssertFalse(session.combatants[0].isConcentrating)
    }

    // MARK: - Inverted resolution

    /// Every other prompt removes its effect on success. This one is the reverse:
    /// the roll is to *keep* the thing.
    func testFailingLosesIt() {
        let (session, id) = session()
        session.toggleConcentration(for: id)
        let prompt = session.applyDamage(to: id, amount: 7)!

        session.resolvePrompt(prompt, succeeded: false)

        XCTAssertFalse(session.combatants[0].isConcentrating)
        XCTAssertTrue(session.log.contains { $0.text.contains("lost concentration") })
    }

    func testSucceedingKeepsIt() {
        let (session, id) = session()
        session.toggleConcentration(for: id)
        let prompt = session.applyDamage(to: id, amount: 7)!

        session.resolvePrompt(prompt, succeeded: true)

        XCTAssertTrue(session.combatants[0].isConcentrating)
        XCTAssertTrue(session.log.contains { $0.text.contains("held concentration") })
    }

    func testTheAnswerLabelsAreSuccessAndFailure() {
        let (session, id) = session()
        session.toggleConcentration(for: id)
        let prompt = session.applyDamage(to: id, amount: 7)!

        XCTAssertEqual(prompt.successLabel, "Success")
        XCTAssertEqual(prompt.failureLabel, "Failure")
    }

    /// Concentration doesn't tick down, so it must survive turns passing.
    func testItSurvivesTurnsPassing() {
        let (session, id) = session()
        session.addCombatant(name: "Goblin", initiative: 5)
        session.toggleConcentration(for: id)

        for _ in 0..<6 { session.nextTurn() }

        XCTAssertTrue(session.combatants.first { $0.id == id }?.isConcentrating == true)
    }
}
