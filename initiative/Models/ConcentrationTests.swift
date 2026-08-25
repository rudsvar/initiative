import XCTest
@testable import initiative

/// Concentration is the one prompt that doesn't come from a turn boundary —
/// damage isn't one — so what's worth testing is when the check appears, and the
/// fact that its sense is inverted from every other prompt.
final class ConcentrationTests: XCTestCase {

    private func session() -> (CombatSession, UUID) {
        let session = CombatSession()
        session.addCombatant(name: "Marchetta", initiative: 20, maxHP: 30, isPlayer: true)
        return (session, session.combatants[0].id)
    }

    private func concentrate(_ session: CombatSession, _ id: UUID, on name: String = "Hold the Bridge") {
        session.addEffect(Effect(name: name, durationType: .untilRemoved, kind: .concentration), to: id)
    }

    func testDamageRaisesACheck() {
        let (session, id) = session()
        concentrate(session, id)

        let prompt = session.applyDamage(to: id, amount: 7)

        XCTAssertNotNil(prompt)
        XCTAssertEqual(prompt?.title, "Roll to hold Hold the Bridge")
        XCTAssertEqual(prompt?.hint, "Took 7 damage", "the app reports the damage, not a DC — the threshold is a rule, and rules are the DM's")
    }

    func testNoCheckWithoutConcentration() {
        let (session, id) = session()
        XCTAssertNil(session.applyDamage(to: id, amount: 7))
    }

    func testHealingRaisesNoCheck() {
        let (session, id) = session()
        concentrate(session, id)
        session.applyDamage(to: id, amount: 5)

        session.applyHealing(to: id, amount: 5)

        XCTAssertEqual(session.combatants[0].effects.filter { $0.kind == .concentration }.count, 1)
    }

    /// Being dropped ends it outright — there's nothing to roll for, so asking
    /// would be a prompt whose answer can't matter.
    func testBeingDroppedToZeroEndsItWithoutAsking() {
        let (session, id) = session()
        concentrate(session, id)

        let prompt = session.applyDamage(to: id, amount: 30)

        XCTAssertNil(prompt)
        XCTAssertTrue(session.combatants[0].effects.filter { $0.kind == .concentration }.isEmpty)
    }

    // MARK: - Inverted resolution

    /// Every other prompt removes its effect on success. This one is the reverse:
    /// the roll is to *keep* the thing.
    func testFailingLosesIt() {
        let (session, id) = session()
        concentrate(session, id)
        let prompt = session.applyDamage(to: id, amount: 7)!

        session.resolvePrompt(prompt, succeeded: false)

        XCTAssertTrue(session.combatants[0].effects.filter { $0.kind == .concentration }.isEmpty)
        XCTAssertTrue(session.log.contains { $0.text.contains("lost Hold the Bridge") })
    }

    func testSucceedingKeepsIt() {
        let (session, id) = session()
        concentrate(session, id)
        let prompt = session.applyDamage(to: id, amount: 7)!

        session.resolvePrompt(prompt, succeeded: true)

        XCTAssertEqual(session.combatants[0].effects.filter { $0.kind == .concentration }.count, 1)
        XCTAssertTrue(session.log.contains { $0.text.contains("held Hold the Bridge") })
    }

    func testTheAnswerLabelsSayWhatTheOutcomeIs() {
        let (session, id) = session()
        concentrate(session, id)
        let prompt = session.applyDamage(to: id, amount: 7)!

        // "Not yet" would be a lie: failing here means something happened.
        XCTAssertEqual(prompt.successLabel, "Held it")
        XCTAssertEqual(prompt.failureLabel, "Lost it")
    }

    /// Concentration doesn't tick down, so it must survive turns passing.
    func testItSurvivesTurnsPassing() {
        let (session, id) = session()
        session.addCombatant(name: "Goblin", initiative: 5)
        concentrate(session, id)

        for _ in 0..<6 { session.nextTurn() }

        XCTAssertEqual(session.combatants.first { $0.id == id }?.effects.filter { $0.kind == .concentration }.count, 1)
    }
}
