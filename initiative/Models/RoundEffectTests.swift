import XCTest
@testable import initiative

/// Round-anchored effects belong to the fight, not to a creature. The point of
/// them is everything a combatant-owned effect can't do: survive that combatant
/// dying, and fire at the top of the round rather than on someone's turn.
final class RoundEffectTests: XCTestCase {

    private func session() -> CombatSession {
        let session = CombatSession()
        session.addCombatant(name: "Marchetta", initiative: 20)
        session.addCombatant(name: "Goblin", initiative: 10)
        return session
    }

    private func advanceARound(_ session: CombatSession) {
        for _ in 0..<session.combatants.count { session.nextTurn() }
    }

    // MARK: - Counting rounds

    func testCountsDownAtTheTopOfEachRound() {
        let session = session()
        session.addRoundEffect(Effect(name: "The bridge is burning", durationType: .forRounds(remaining: 2)))

        advanceARound(session)

        XCTAssertEqual(session.roundEffects.first?.durationType, .forRounds(remaining: 1))
    }

    /// It must not tick on every turn — that's the bug pinning it to a combatant
    /// would have caused.
    func testDoesNotCountDownOnAnIntermediateTurn() {
        let session = session()
        session.addRoundEffect(Effect(name: "Bridge", durationType: .forRounds(remaining: 3)))

        session.nextTurn() // Marchetta -> Goblin, still round 1

        XCTAssertEqual(session.roundEffects.first?.durationType, .forRounds(remaining: 3))
    }

    func testExpiresWhenTheCountRunsOut() {
        let session = session()
        session.addRoundEffect(Effect(name: "Bridge", durationType: .forRounds(remaining: 1)))

        advanceARound(session)

        XCTAssertTrue(session.roundEffects.isEmpty)
        XCTAssertTrue(session.log.contains { $0.text.contains("Round effect ended") })
    }

    func testUntilRemovedSurvivesRounds() {
        let session = session()
        session.addRoundEffect(Effect(name: "Darkness", durationType: .untilRemoved))

        for _ in 0..<8 { session.nextTurn() }

        XCTAssertEqual(session.roundEffects.count, 1)
    }

    /// The reason these don't live on a combatant.
    func testSurvivesEveryCombatantBeingRemoved() {
        let session = session()
        session.addRoundEffect(Effect(name: "Bridge", durationType: .forRounds(remaining: 3)))

        for combatant in session.combatants { session.removeCombatant(id: combatant.id) }

        XCTAssertEqual(session.roundEffects.count, 1)
    }

    // MARK: - Prompting

    func testARollIsAskedForWhenTheRoundTurnsOver() {
        let session = session()
        session.addRoundEffect(Effect(
            name: "The lair stirs",
            durationType: .untilRollSucceeds(at: .startOfTurn, hint: "5–6 on a d6")
        ))

        // Not on the first advance — the round hasn't wrapped yet.
        XCTAssertTrue(session.pendingTurnPrompts().isEmpty)
        session.nextTurn()

        let prompts = session.pendingTurnPrompts()
        XCTAssertEqual(prompts.count, 1)
        XCTAssertEqual(prompts.first?.combatantName, "The round")
        XCTAssertNil(prompts.first?.combatantID, "the round belongs to no one")
        XCTAssertEqual(prompts.first?.hint, "5–6 on a d6")
    }

    func testSucceedingEndsIt() {
        let session = session()
        session.addRoundEffect(Effect(name: "The lair stirs", durationType: .untilRollSucceeds(at: .startOfTurn, hint: nil)))
        session.nextTurn()
        let prompt = session.pendingTurnPrompts().first!

        session.nextTurn(resolving: [prompt: .success])

        XCTAssertTrue(session.roundEffects.isEmpty)
    }

    func testFailingLeavesItToAskAgainNextRound() {
        let session = session()
        session.addRoundEffect(Effect(name: "The lair stirs", durationType: .untilRollSucceeds(at: .startOfTurn, hint: nil)))
        session.nextTurn()

        session.nextTurn(resolving: [session.pendingTurnPrompts().first!: .failure])
        session.nextTurn()

        XCTAssertEqual(session.pendingTurnPrompts().count, 1)
    }

    // MARK: - Undo and persistence

    func testPreviousTurnRestoresTheCountdown() {
        let session = session()
        session.addRoundEffect(Effect(name: "Bridge", durationType: .forRounds(remaining: 2)))
        advanceARound(session)
        XCTAssertEqual(session.roundEffects.first?.durationType, .forRounds(remaining: 1))

        session.previousTurn()

        XCTAssertEqual(session.roundEffects.first?.durationType, .forRounds(remaining: 2))
    }

    func testRoundEffectsSurviveSaveAndLoad() throws {
        let session = session()
        session.addRoundEffect(Effect(name: "Bridge", durationType: .forRounds(remaining: 3)))

        let data = try JSONEncoder().encode(session.makeRecord())
        let restored = CombatSession()
        restored.load(try JSONDecoder().decode(SessionRecord.self, from: data))

        XCTAssertEqual(restored.roundEffects.first?.name, "Bridge")
        XCTAssertEqual(restored.roundEffects.first?.durationType, .forRounds(remaining: 3))
    }

    /// Sessions saved before round effects existed have no such key.
    func testARecordWithoutRoundEffectsLoadsEmpty() throws {
        let json = """
        {"id":"\(UUID().uuidString)","name":"Old","savedAt":0,"combatants":[],"currentTurnIndex":0}
        """.data(using: .utf8)!

        let record = try JSONDecoder().decode(SessionRecord.self, from: json)
        let session = CombatSession()
        session.load(record)

        XCTAssertTrue(session.roundEffects.isEmpty)
    }

    func testResetClearsThem() {
        let session = session()
        session.addRoundEffect(Effect(name: "Bridge", durationType: .untilRemoved))

        session.reset()

        XCTAssertTrue(session.roundEffects.isEmpty)
    }

    /// A round effect's roll comes when the round turns over, not on anyone's turn.
    func testARoundEffectsRollIsDescribedByTheRound() {
        XCTAssertEqual(
            DurationType.untilRollSucceeds(at: .startOfTurn, hint: "DC 12 Dex").roundDescription,
            "Until a roll succeeds, when the round turns over (DC 12 Dex)"
        )
        XCTAssertEqual(DurationType.forRounds(remaining: 3).roundDescription, "For 3 more rounds")
        XCTAssertEqual(DurationType.untilRemoved.roundDescription, "Until removed")
    }
}
