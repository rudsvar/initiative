import XCTest
@testable import initiative

final class DeathSaveTests: XCTestCase {

    private func session(playerHP: Int = 10) -> (CombatSession, UUID) {
        let session = CombatSession()
        session.addCombatant(name: "Wren", initiative: 20, maxHP: playerHP, isPlayer: true)
        session.addCombatant(name: "Goblin", initiative: 10, maxHP: 7, isPlayer: false)
        return (session, session.combatants.first { $0.name == "Wren" }!.id)
    }

    private func combatant(_ session: CombatSession, _ name: String) -> Combatant {
        session.combatants.first { $0.name == name }!
    }

    // MARK: - Starting

    /// The whole reason `isPlayer` exists: without it, auto-starting death saves
    /// would put a clock on every goblin the party kills.
    func testAPlayerAtZeroStartsDying() {
        let (session, wren) = session()
        session.applyDamage(to: wren, amount: 10)

        XCTAssertTrue(combatant(session, "Wren").isDying)
        XCTAssertFalse(combatant(session, "Wren").isDead)
    }

    func testAnNPCAtZeroIsSimplyDead() {
        let (session, _) = session()
        let goblin = combatant(session, "Goblin").id

        session.applyDamage(to: goblin, amount: 7)

        XCTAssertFalse(combatant(session, "Goblin").isDying)
        XCTAssertTrue(combatant(session, "Goblin").isDead)
    }

    /// Damage taken while already down mustn't restart the tally.
    func testFurtherDamageDoesNotResetTheTally() {
        let (session, wren) = session()
        session.applyDamage(to: wren, amount: 10)
        answerDeathSave(session, success: false)

        session.applyDamage(to: wren, amount: 3)

        XCTAssertEqual(combatant(session, "Wren").deathSaves?.failures, 1)
    }

    // MARK: - Resolving

    func testThreeFailuresKills() {
        let (session, wren) = session()
        session.applyDamage(to: wren, amount: 10)

        for _ in 0..<3 {
            answerDeathSave(session, success: false)
        }

        XCTAssertTrue(combatant(session, "Wren").isDead)
        XCTAssertFalse(combatant(session, "Wren").isDying)
    }

    /// Stabilised is a real third state: at 0 HP, not rolling, and explicitly not
    /// dead. It has to be distinguishable from both neighbours.
    func testThreeSuccessesStabilises() {
        let (session, wren) = session()
        session.applyDamage(to: wren, amount: 10)

        for _ in 0..<3 {
            answerDeathSave(session, success: true)
        }

        let wrenNow = combatant(session, "Wren")
        XCTAssertTrue(wrenNow.isStabilised)
        XCTAssertFalse(wrenNow.isDead)
        XCTAssertFalse(wrenNow.isDying)
        XCTAssertEqual(wrenNow.currentHP, 0)
    }

    func testMixedResultsKeepBothTallies() {
        let (session, wren) = session()
        session.applyDamage(to: wren, amount: 10)

        answerDeathSave(session, success: true)
        answerDeathSave(session, success: false)

        XCTAssertEqual(combatant(session, "Wren").deathSaves?.successes, 1)
        XCTAssertEqual(combatant(session, "Wren").deathSaves?.failures, 1)
        XCTAssertTrue(combatant(session, "Wren").isDying)
    }

    func testARecordedSaveDoesNotMoveOnceResolved() {
        var saves = DeathSaves(successes: 3, failures: 0)
        saves.record(success: false)
        XCTAssertEqual(saves.failures, 0, "a resolved tally must not keep accumulating")
    }

    // MARK: - Healing

    func testHealingAboveZeroEndsIt() {
        let (session, wren) = session()
        session.applyDamage(to: wren, amount: 10)
        answerDeathSave(session, success: false)

        session.applyHealing(to: wren, amount: 4)

        XCTAssertNil(combatant(session, "Wren").deathSaves)
        XCTAssertFalse(combatant(session, "Wren").isDying)
    }

    /// The log is the HP undo mechanism, so deleting the blow that dropped
    /// someone has to take the dying state with it — otherwise they're left
    /// rolling death saves at full health.
    func testUndoingTheKillingBlowEndsIt() {
        let (session, wren) = session()
        session.applyDamage(to: wren, amount: 10)
        let damageEntry = session.log.last { $0.hpOperation != nil }!

        session.deleteLogEntry(damageEntry.id)

        XCTAssertEqual(combatant(session, "Wren").currentHP, 10)
        XCTAssertNil(combatant(session, "Wren").deathSaves)
    }

    // MARK: - Prompting

    func testADyingCombatantIsPromptedAtTheStartOfTheirTurn() {
        let (session, wren) = session()
        session.applyDamage(to: wren, amount: 10)
        // Wren rolls 20 and goes first, so advancing from the goblin comes back round.
        session.nextTurn()

        let prompts = session.pendingTurnPrompts()

        XCTAssertEqual(prompts.count, 1)
        XCTAssertEqual(prompts.first?.combatantName, "Wren")
        XCTAssertEqual(prompts.first?.subject, .deathSave)
    }

    func testNoPromptOnceStabilised() {
        let (session, wren) = session()
        session.applyDamage(to: wren, amount: 10)
        for _ in 0..<3 { answerDeathSave(session, success: true) }

        XCTAssertTrue(session.pendingTurnPrompts().isEmpty)
    }

    /// Answers ride inside the same undo step as the turn they were given on, so
    /// Previous rewinds the save rather than leaving it stranded.
    func testPreviousTurnUndoesTheSaveItWasGivenWith() {
        let (session, wren) = session()
        session.applyDamage(to: wren, amount: 10)
        answerDeathSave(session, success: false)
        XCTAssertEqual(combatant(session, "Wren").deathSaves?.failures, 1)

        session.previousTurn()

        XCTAssertEqual(combatant(session, "Wren").deathSaves?.failures, 0)
    }

    // MARK: - Helpers

    /// Advances turns until Wren's death save comes up, then answers it — the
    /// only way the tally can move, since nothing else touches it.
    private func answerDeathSave(_ session: CombatSession, success: Bool) {
        for _ in 0..<(session.combatants.count + 1) {
            if let prompt = session.pendingTurnPrompts().first(where: { $0.subject == .deathSave }) {
                session.nextTurn(resolving: [prompt: success])
                return
            }
            session.nextTurn()
        }
        XCTFail("no death save prompt appeared")
    }
}
