import XCTest
@testable import initiative

final class TurnPromptTests: XCTestCase {

    private func session() -> CombatSession {
        let session = CombatSession()
        session.addCombatant(name: "Dragon", initiative: 20)
        session.addCombatant(name: "Wren", initiative: 10, maxHP: 20, isPlayer: true)
        return session
    }

    private func id(_ session: CombatSession, _ name: String) -> UUID {
        session.combatants.first { $0.name == name }!.id
    }

    private func addEffect(_ session: CombatSession, to name: String, _ effect: Effect) {
        let index = session.combatants.firstIndex { $0.name == name }!
        session.combatants[index].effects.append(effect)
    }

    // MARK: - Never expiring on its own

    /// The point of the case: it waits on the DM rather than a counter, so no
    /// number of turns may remove it.
    func testARollRequiredEffectNeverAgesOut() {
        let session = session()
        addEffect(session, to: "Dragon", Effect(
            name: "Breath Weapon",
            durationType: .untilRollSucceeds(at: .startOfTurn, hint: "5–6 on a d6"),
            kind: .cooldown
        ))

        for _ in 0..<10 {
            session.nextTurn(resolving: [:])
        }

        XCTAssertEqual(session.combatants.first { $0.name == "Dragon" }?.effects.count, 1)
    }

    // MARK: - Which boundary

    func testStartOfTurnEffectsPromptForTheIncomingCombatant() {
        let session = session()
        addEffect(session, to: "Wren", Effect(
            name: "Recharging",
            durationType: .untilRollSucceeds(at: .startOfTurn, hint: nil),
            kind: .cooldown
        ))

        // Dragon is current (initiative 20); advancing starts Wren's turn.
        let prompts = session.pendingTurnPrompts()

        XCTAssertEqual(prompts.count, 1)
        XCTAssertEqual(prompts.first?.combatantName, "Wren")
        XCTAssertEqual(prompts.first?.title, "Roll: Recharging")
    }

    func testEndOfTurnEffectsPromptForTheOutgoingCombatant() {
        let session = session()
        addEffect(session, to: "Dragon", Effect(
            name: "Frightened",
            durationType: .untilRollSucceeds(at: .endOfTurn, hint: "DC 14"),
            kind: .condition
        ))

        let prompts = session.pendingTurnPrompts()

        XCTAssertEqual(prompts.count, 1)
        XCTAssertEqual(prompts.first?.combatantName, "Dragon")
        XCTAssertEqual(prompts.first?.title, "Roll a save vs Frightened")
        XCTAssertEqual(prompts.first?.hint, "DC 14")
    }

    /// Both belong to the same tap on Next even though they belong to different
    /// combatants — one interruption at the boundary rather than two either side.
    func testBothEndsOfTheBoundaryAreAskedTogether() {
        let session = session()
        addEffect(session, to: "Dragon", Effect(
            name: "Frightened",
            durationType: .untilRollSucceeds(at: .endOfTurn, hint: nil)
        ))
        addEffect(session, to: "Wren", Effect(
            name: "Recharging",
            durationType: .untilRollSucceeds(at: .startOfTurn, hint: nil),
            kind: .cooldown
        ))

        XCTAssertEqual(Set(session.pendingTurnPrompts().map(\.combatantName)), ["Dragon", "Wren"])
    }

    func testNoPromptsWhenNothingIsOwed() {
        XCTAssertTrue(session().pendingTurnPrompts().isEmpty)
    }

    func testOrdinaryCountdownsAreNotPrompted() {
        let session = session()
        addEffect(session, to: "Wren", Effect(name: "Blinded", durationType: .untilEndOfTheirTurn(remainingTurns: 3)))

        XCTAssertTrue(session.pendingTurnPrompts().isEmpty)
    }

    // MARK: - Answers

    func testSuccessRemovesTheEffect() {
        let session = session()
        addEffect(session, to: "Wren", Effect(
            name: "Recharging",
            durationType: .untilRollSucceeds(at: .startOfTurn, hint: nil),
            kind: .cooldown
        ))
        let prompt = session.pendingTurnPrompts().first!

        session.nextTurn(resolving: [prompt: .success])

        XCTAssertTrue(session.combatants.first { $0.name == "Wren" }!.effects.isEmpty)
    }

    func testFailureLeavesTheEffectInPlaceToAskAgain() {
        let session = session()
        addEffect(session, to: "Wren", Effect(
            name: "Recharging",
            durationType: .untilRollSucceeds(at: .startOfTurn, hint: nil),
            kind: .cooldown
        ))

        session.nextTurn(resolving: [session.pendingTurnPrompts().first!: .failure])
        // Round the table back to Wren.
        session.nextTurn()

        XCTAssertEqual(session.pendingTurnPrompts().count, 1)
    }

    func testAnsweringIsUndoneAlongWithTheTurn() {
        let session = session()
        addEffect(session, to: "Wren", Effect(
            name: "Recharging",
            durationType: .untilRollSucceeds(at: .startOfTurn, hint: nil),
            kind: .cooldown
        ))

        session.nextTurn(resolving: [session.pendingTurnPrompts().first!: .success])
        session.previousTurn()

        XCTAssertEqual(session.combatants.first { $0.name == "Wren" }?.effects.count, 1)
    }

    /// The verb comes from the kind, which is the only thing that distinguishes a
    /// recharge from a save — the mechanism underneath is identical.
    func testTheVerbFollowsTheEffectKind() {
        let session = session()
        addEffect(session, to: "Wren", Effect(
            name: "Thing",
            durationType: .untilRollSucceeds(at: .startOfTurn, hint: nil),
            kind: .condition
        ))

        XCTAssertEqual(session.pendingTurnPrompts().first?.title, "Roll a save vs Thing")
    }

    func testRechargeTitleDoesNotRepeatTheWord() {
        XCTAssertEqual(CombatSession.rechargeTitle(for: "Recharging"), "Roll: Recharging")
        XCTAssertEqual(CombatSession.rechargeTitle(for: "Breath Weapon"), "Roll to recharge Breath Weapon")
    }

    /// The dead roll nothing: a creature killed on its own turn is not asked its
    /// end-of-turn save, or whether it attacked while invisible.
    func testADeadCombatantIsNotAskedItsPrompts() {
        let session = CombatSession()
        session.addCombatant(name: "Alpha", initiative: 20, maxHP: 10)
        session.addCombatant(name: "Beta", initiative: 15, maxHP: 10)
        let alpha = session.combatants[0].id
        session.addEffect(Effect(name: "Frightened", durationType: .untilRollSucceeds(at: .endOfTurn, hint: nil)), to: alpha)
        session.addEffect(Effect(name: "Invisible", durationType: .untilRemoved), to: alpha)
        session.kill(alpha)
        XCTAssertTrue(session.pendingTurnPrompts().isEmpty)
    }
}
