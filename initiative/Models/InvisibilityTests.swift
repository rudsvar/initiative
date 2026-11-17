import XCTest
@testable import initiative

/// Ordinary invisibility ends when the creature attacks, deals damage or casts a
/// spell. The app can't see that, so it asks at the end of the invisible
/// creature's turn: yes ends it, no keeps it. Greater invisibility isn't broken
/// that way, so it never asks.
final class InvisibilityTests: XCTestCase {
    private func session(effect name: String = "Invisible") -> CombatSession {
        let session = CombatSession()
        session.addCombatant(name: "Wren", initiative: 20, isPlayer: true)
        session.addCombatant(name: "Goblin", initiative: 10)
        session.combatants[0].effects.append(Effect(name: name, durationType: .untilRemoved))
        return session
    }

    private func wren(_ session: CombatSession) -> Combatant { session.combatants.first { $0.name == "Wren" }! }

    private func actionPrompt(_ session: CombatSession) -> TurnPrompt? {
        session.pendingTurnPrompts().first { if case .endsOnAction = $0.subject { true } else { false } }
    }

    func testTheInvisibleCombatantIsAskedAsItsTurnEnds() {
        let prompt = actionPrompt(session())
        XCTAssertEqual(prompt?.combatantName, "Wren")
        XCTAssertEqual(prompt?.title, "Did Wren attack, deal damage or cast a spell?")
    }

    func testNothingIsAskedAtTheEndOfSomeoneElsesTurn() {
        let session = session()
        session.nextTurn()   // the Goblin's turn; Wren's starts next
        XCTAssertNil(actionPrompt(session))
    }

    func testYesEndsInvisible() {
        let session = session()
        session.nextTurn(resolving: [actionPrompt(session)!: .success])
        XCTAssertFalse(wren(session).effects.contains { $0.name == "Invisible" })
        XCTAssertTrue(session.log.contains { $0.text == "Wren is no longer Invisible" })
    }

    func testNoKeepsInvisible() {
        let session = session()
        session.nextTurn(resolving: [actionPrompt(session)!: .failure])
        XCTAssertTrue(wren(session).effects.contains { $0.name == "Invisible" })
    }

    func testPreviousBringsInvisibleBack() {
        let session = session()
        session.nextTurn(resolving: [actionPrompt(session)!: .success])
        session.previousTurn()
        XCTAssertTrue(wren(session).effects.contains { $0.name == "Invisible" })
    }

    func testATypedNameInAnyCaseAsksToo() {
        XCTAssertNotNil(actionPrompt(session(effect: "invisible")))
    }

    func testGreaterInvisibleNeverAsks() {
        XCTAssertNil(actionPrompt(session(effect: "Greater Invisible")))
    }

    func testTheAnswersReadAsAYesOrNoQuestion() {
        let prompt = actionPrompt(session())!
        XCTAssertEqual(prompt.successLabel, "Yes, it ends")
        XCTAssertEqual(prompt.failureLabel, "No")
    }

    func testGreaterInvisibleIsAConditionThatLastsTenTurns() {
        let condition = ConditionLibrary.matching(name: "Greater Invisible")
        XCTAssertEqual(condition?.category, .sensory)
        XCTAssertEqual(condition?.defaultDuration, .untilEndOfTheirTurn(remainingTurns: 10))
    }
}
