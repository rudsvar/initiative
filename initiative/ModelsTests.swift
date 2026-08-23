import XCTest
@testable import initiative

final class CombatSessionTests: XCTestCase {
    var session: CombatSession!

    override func setUp() {
        super.setUp()
        session = CombatSession()
    }

    // MARK: - Participant Management

    func testAddParticipant() {
        session.addParticipant(name: "Goblin", initiative: 15)
        XCTAssertEqual(session.participants.count, 1)
        XCTAssertEqual(session.participants.first?.name, "Goblin")
        XCTAssertEqual(session.participants.first?.initiative, 15)
    }

    func testParticipantsSortedByInitiativeDescending() {
        session.addParticipant(name: "Slow", initiative: 5)
        session.addParticipant(name: "Fast", initiative: 20)
        session.addParticipant(name: "Medium", initiative: 12)

        let sorted = session.sortedParticipants
        XCTAssertEqual(sorted[0].initiative, 20)
        XCTAssertEqual(sorted[1].initiative, 12)
        XCTAssertEqual(sorted[2].initiative, 5)
    }

    func testCurrentParticipantTracking() {
        session.addParticipant(name: "P1", initiative: 10)
        session.addParticipant(name: "P2", initiative: 20)

        XCTAssertEqual(session.currentParticipant?.name, "P2") // Highest initiative goes first
    }

    // MARK: - Reaction Management

    func testReactionResetOnTurnStart() {
        session.addParticipant(name: "Warrior", initiative: 15)
        let warrior = session.participants.first!

        // Use reaction
        session.participants[0].reactionUsed = true
        XCTAssertTrue(warrior.reactionUsed)

        // Advance turn
        session.nextTurn()

        // Reaction should be reset
        XCTAssertFalse(session.participants[0].reactionUsed)
    }

    func testReactionPersistsThroughOtherTurns() {
        session.addParticipant(name: "P1", initiative: 20)
        session.addParticipant(name: "P2", initiative: 10)

        // P1 uses reaction
        session.participants[0].reactionUsed = true

        // Advance to P2's turn
        session.nextTurn()

        // P1's reaction should still be used
        XCTAssertTrue(session.participants[0].reactionUsed)

        // Reset to P1's turn
        session.nextTurn()

        // P1's reaction should now be reset
        XCTAssertFalse(session.participants[0].reactionUsed)
    }

    // MARK: - Turn Advancement

    func testNextTurnAdvancesParticipant() {
        session.addParticipant(name: "P1", initiative: 20)
        session.addParticipant(name: "P2", initiative: 10)

        XCTAssertEqual(session.currentTurnIndex, 0)
        session.nextTurn()
        XCTAssertEqual(session.currentTurnIndex, 1)
    }

    func testNextTurnWrapsAround() {
        session.addParticipant(name: "P1", initiative: 20)
        session.addParticipant(name: "P2", initiative: 10)

        session.nextTurn() // 0 -> 1
        session.nextTurn() // 1 -> 0 (wrap)

        XCTAssertEqual(session.currentTurnIndex, 0)
    }

    func testNextTurnWithNoParticipants() {
        // Should not crash
        session.nextTurn()
        XCTAssertEqual(session.currentTurnIndex, 0)
    }

    // MARK: - Effect Management

    func testAddEffectToParticipant() {
        session.addParticipant(name: "Mage", initiative: 15)
        let effect = Effect(name: "Stunned", durationType: .untilStartOfTheirTurn)

        session.participants[0].effects.append(effect)

        XCTAssertEqual(session.participants[0].effects.count, 1)
        XCTAssertEqual(session.participants[0].effects.first?.name, "Stunned")
    }

    func testEffectUntilStartOfTheirTurnExpires() {
        session.addParticipant(name: "P1", initiative: 20)
        session.addParticipant(name: "P2", initiative: 10)

        let effect = Effect(name: "Stunned", durationType: .untilStartOfTheirTurn)
        session.participants[0].effects.append(effect)

        XCTAssertEqual(session.participants[0].effects.count, 1)

        // P1's turn ends, P2's begins
        session.nextTurn()

        // P2's turn ends, P1's begins again
        session.nextTurn()

        // Effect should be removed (expired at start of P1's turn)
        XCTAssertEqual(session.participants[0].effects.count, 0)
    }

    func testEffectUntilEndOfTheirTurnPersistsUntilNextStart() {
        session.addParticipant(name: "P1", initiative: 20)
        session.addParticipant(name: "P2", initiative: 10)

        let effect = Effect(name: "Poisoned", durationType: .untilEndOfTheirTurn)
        session.participants[0].effects.append(effect)

        // P1's turn ends
        session.nextTurn()

        // Effect should still be there (only expires at end of P1's turn, not start)
        XCTAssertEqual(session.participants[0].effects.count, 1)

        // P2's turn ends, back to P1
        session.nextTurn()

        // Now effect should be gone (it expired at end of P1's turn)
        XCTAssertEqual(session.participants[0].effects.count, 0)
    }

    func testEffectUntilStartOfTargetTurn() {
        session.addParticipant(name: "P1", initiative: 20)
        session.addParticipant(name: "P2", initiative: 10)

        let p2Id = session.participants[1].id
        let effect = Effect(
            name: "Marked",
            durationType: .untilStartOfTargetTurn(targetID: p2Id)
        )
        session.participants[0].effects.append(effect)

        XCTAssertEqual(session.participants[0].effects.count, 1)

        // P1's turn ends, P2's begins
        session.nextTurn()

        // Effect should be removed (expired at start of P2's turn)
        XCTAssertEqual(session.participants[0].effects.count, 0)
    }

    func testEffectUntilEndOfTargetTurn() {
        session.addParticipant(name: "P1", initiative: 20)
        session.addParticipant(name: "P2", initiative: 10)

        let p2Id = session.participants[1].id
        let effect = Effect(
            name: "Blessed",
            durationType: .untilEndOfTargetTurn(targetID: p2Id)
        )
        session.participants[0].effects.append(effect)

        // P1's turn ends, P2's begins
        session.nextTurn()

        // Effect still active (expires at end of P2's turn, not start)
        XCTAssertEqual(session.participants[0].effects.count, 1)

        // P2's turn ends, back to P1
        session.nextTurn()

        // Effect now expired
        XCTAssertEqual(session.participants[0].effects.count, 0)
    }

    func testMultipleEffectsDifferentDurations() {
        session.addParticipant(name: "P1", initiative: 20)
        session.addParticipant(name: "P2", initiative: 10)

        let p2Id = session.participants[1].id

        let effect1 = Effect(name: "E1", durationType: .untilStartOfTheirTurn)
        let effect2 = Effect(name: "E2", durationType: .untilEndOfTheirTurn)
        let effect3 = Effect(name: "E3", durationType: .untilStartOfTargetTurn(targetID: p2Id))

        session.participants[0].effects.append(contentsOf: [effect1, effect2, effect3])
        XCTAssertEqual(session.participants[0].effects.count, 3)

        // Advance turns
        session.nextTurn()

        // Only effect1 and effect3 should expire (start-based)
        XCTAssertEqual(session.participants[0].effects.count, 1)
        XCTAssertEqual(session.participants[0].effects.first?.name, "E2")
    }
}

final class ParticipantTests: XCTestCase {
    func testParticipantInitialization() {
        let participant = Participant(name: "Rogue", initiative: 18)

        XCTAssertEqual(participant.name, "Rogue")
        XCTAssertEqual(participant.initiative, 18)
        XCTAssertFalse(participant.reactionUsed)
        XCTAssertTrue(participant.effects.isEmpty)
    }

    func testParticipantIDUniqueness() {
        let p1 = Participant(name: "P1", initiative: 10)
        let p2 = Participant(name: "P2", initiative: 10)

        XCTAssertNotEqual(p1.id, p2.id)
    }
}

final class EffectTests: XCTestCase {
    func testEffectInitialization() {
        let effect = Effect(name: "Stunned", durationType: .untilStartOfTheirTurn)

        XCTAssertEqual(effect.name, "Stunned")
        XCTAssertEqual(effect.durationType, .untilStartOfTheirTurn)
    }

    func testDurationTypeDescription() {
        XCTAssertEqual(
            DurationType.untilStartOfTheirTurn.description,
            "Until start of their next turn"
        )
        XCTAssertEqual(
            DurationType.untilEndOfTheirTurn.description,
            "Until end of their next turn"
        )
        XCTAssertEqual(
            DurationType.untilStartOfTargetTurn(targetID: UUID()).description,
            "Until start of target's next turn"
        )
        XCTAssertEqual(
            DurationType.untilEndOfTargetTurn(targetID: UUID()).description,
            "Until end of target's next turn"
        )
    }
}
