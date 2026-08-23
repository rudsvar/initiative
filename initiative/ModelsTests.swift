import XCTest
@testable import initiative

final class CombatSessionTests: XCTestCase {
    var session: CombatSession!

    override func setUp() {
        super.setUp()
        session = CombatSession()
    }

    // MARK: - Combatant Management

    func testAddCombatant() {
        session.addCombatant(name: "Goblin", initiative: 15)
        XCTAssertEqual(session.combatants.count, 1)
        XCTAssertEqual(session.combatants.first?.name, "Goblin")
        XCTAssertEqual(session.combatants.first?.initiative, 15)
    }

    func testCombatantsSortedByInitiativeDescending() {
        session.addCombatant(name: "Slow", initiative: 5)
        session.addCombatant(name: "Fast", initiative: 20)
        session.addCombatant(name: "Medium", initiative: 12)

        let sorted = session.sortedCombatants
        XCTAssertEqual(sorted[0].initiative, 20)
        XCTAssertEqual(sorted[1].initiative, 12)
        XCTAssertEqual(sorted[2].initiative, 5)
    }

    func testCurrentCombatantTracking() {
        session.addCombatant(name: "P1", initiative: 10)
        session.addCombatant(name: "P2", initiative: 20)

        XCTAssertEqual(session.currentCombatant?.name, "P2") // Highest initiative goes first
    }

    // MARK: - Reaction Management

    func testReactionResetOnTurnStart() {
        session.addCombatant(name: "Warrior", initiative: 15)

        // Use reaction
        session.combatants[0].reactionUsed = true
        XCTAssertTrue(session.combatants[0].reactionUsed)

        // Advance turn
        session.nextTurn()

        // Reaction should be reset
        XCTAssertFalse(session.combatants[0].reactionUsed)
    }

    func testReactionPersistsThroughOtherTurns() {
        session.addCombatant(name: "P1", initiative: 20)
        session.addCombatant(name: "P2", initiative: 10)

        // P1 uses reaction
        session.combatants[0].reactionUsed = true

        // Advance to P2's turn
        session.nextTurn()

        // P1's reaction should still be used
        XCTAssertTrue(session.combatants[0].reactionUsed)

        // Reset to P1's turn
        session.nextTurn()

        // P1's reaction should now be reset
        XCTAssertFalse(session.combatants[0].reactionUsed)
    }

    // MARK: - Turn Advancement

    func testNextTurnAdvancesCombatant() {
        session.addCombatant(name: "P1", initiative: 20)
        session.addCombatant(name: "P2", initiative: 10)

        XCTAssertEqual(session.currentTurnIndex, 0)
        session.nextTurn()
        XCTAssertEqual(session.currentTurnIndex, 1)
    }

    func testNextTurnWrapsAround() {
        session.addCombatant(name: "P1", initiative: 20)
        session.addCombatant(name: "P2", initiative: 10)

        session.nextTurn() // 0 -> 1
        session.nextTurn() // 1 -> 0 (wrap)

        XCTAssertEqual(session.currentTurnIndex, 0)
    }

    func testNextTurnWithNoCombatants() {
        // Should not crash
        session.nextTurn()
        XCTAssertEqual(session.currentTurnIndex, 0)
    }

    // MARK: - Previous Turn

    func testCanGoToPreviousTurnInitiallyFalse() {
        session.addCombatant(name: "P1", initiative: 20)
        XCTAssertFalse(session.canGoToPreviousTurn)
    }

    func testPreviousTurnRevertsIndex() {
        session.addCombatant(name: "P1", initiative: 20)
        session.addCombatant(name: "P2", initiative: 10)

        session.nextTurn() // 0 -> 1
        XCTAssertTrue(session.canGoToPreviousTurn)

        session.previousTurn() // 1 -> 0
        XCTAssertEqual(session.currentTurnIndex, 0)
        XCTAssertFalse(session.canGoToPreviousTurn)
    }

    func testPreviousTurnRevertsReactionState() {
        session.addCombatant(name: "P1", initiative: 20)
        session.addCombatant(name: "P2", initiative: 10)

        session.combatants[0].reactionUsed = true
        session.nextTurn() // resets P2's reaction, P1's stays used

        session.previousTurn()

        XCTAssertTrue(session.combatants[0].reactionUsed)
    }

    func testPreviousTurnRevertsExpiredEffects() {
        session.addCombatant(name: "P1", initiative: 20)
        session.addCombatant(name: "P2", initiative: 10)

        let effect = Effect(name: "Poisoned", durationType: .untilEndOfTheirTurn)
        session.combatants[0].effects.append(effect)

        session.nextTurn() // effect expires
        XCTAssertEqual(session.combatants[0].effects.count, 0)

        session.previousTurn()
        XCTAssertEqual(session.combatants[0].effects.count, 1)
    }

    func testPreviousTurnWithNoHistoryDoesNothing() {
        session.addCombatant(name: "P1", initiative: 20)
        session.previousTurn()
        XCTAssertEqual(session.currentTurnIndex, 0)
    }

    // MARK: - Reset & Records

    func testResetClearsCombatantsAndHistory() {
        session.addCombatant(name: "P1", initiative: 20)
        session.addCombatant(name: "P2", initiative: 10)
        session.nextTurn()

        session.reset()

        XCTAssertTrue(session.combatants.isEmpty)
        XCTAssertEqual(session.currentTurnIndex, 0)
        XCTAssertFalse(session.canGoToPreviousTurn)
    }

    func testMakeRecordCapturesState() {
        session.addCombatant(name: "P1", initiative: 20)
        session.nextTurn()

        let record = session.makeRecord()

        XCTAssertEqual(record.id, session.id)
        XCTAssertEqual(record.name, session.name)
        XCTAssertEqual(record.combatants.count, 1)
        XCTAssertEqual(record.currentTurnIndex, session.currentTurnIndex)
    }

    func testLoadRecordRestoresStateAndClearsHistory() {
        session.addCombatant(name: "P1", initiative: 20)
        session.addCombatant(name: "P2", initiative: 10)
        session.nextTurn()
        let record = session.makeRecord()

        session.reset()
        session.addCombatant(name: "Other", initiative: 5)

        session.load(record)

        XCTAssertEqual(session.id, record.id)
        XCTAssertEqual(session.name, record.name)
        XCTAssertEqual(session.combatants.count, 2)
        XCTAssertEqual(session.currentTurnIndex, record.currentTurnIndex)
        XCTAssertFalse(session.canGoToPreviousTurn)
    }

    func testResetAssignsFreshIdentity() {
        let originalId = session.id
        session.reset()
        XCTAssertNotEqual(session.id, originalId)
    }

    // MARK: - Effect Management

    func testAddEffectToCombatant() {
        session.addCombatant(name: "Mage", initiative: 15)
        let effect = Effect(name: "Stunned", durationType: .untilStartOfTheirTurn)

        session.combatants[0].effects.append(effect)

        XCTAssertEqual(session.combatants[0].effects.count, 1)
        XCTAssertEqual(session.combatants[0].effects.first?.name, "Stunned")
    }

    func testEffectUntilStartOfTheirTurnExpires() {
        session.addCombatant(name: "P1", initiative: 20)
        session.addCombatant(name: "P2", initiative: 10)

        let effect = Effect(name: "Stunned", durationType: .untilStartOfTheirTurn)
        session.combatants[0].effects.append(effect)

        XCTAssertEqual(session.combatants[0].effects.count, 1)

        // P1's turn ends, P2's begins
        session.nextTurn()

        // P2's turn ends, P1's begins again
        session.nextTurn()

        // Effect should be removed (expired at start of P1's turn)
        XCTAssertEqual(session.combatants[0].effects.count, 0)
    }

    func testEffectUntilEndOfTheirTurnExpiresWhenOwnersTurnEnds() {
        session.addCombatant(name: "P1", initiative: 20)
        session.addCombatant(name: "P2", initiative: 10)

        let effect = Effect(name: "Poisoned", durationType: .untilEndOfTheirTurn)
        session.combatants[0].effects.append(effect)

        // P1's turn ends (the trigger condition), P2's begins
        session.nextTurn()

        // Effect expires immediately since P1's turn just ended
        XCTAssertEqual(session.combatants[0].effects.count, 0)
    }

    func testEffectUntilStartOfTargetTurn() {
        session.addCombatant(name: "P1", initiative: 20)
        session.addCombatant(name: "P2", initiative: 10)

        let p2Id = session.combatants[1].id
        let effect = Effect(
            name: "Marked",
            durationType: .untilStartOfTargetTurn(targetID: p2Id)
        )
        session.combatants[0].effects.append(effect)

        XCTAssertEqual(session.combatants[0].effects.count, 1)

        // P1's turn ends, P2's begins
        session.nextTurn()

        // Effect should be removed (expired at start of P2's turn)
        XCTAssertEqual(session.combatants[0].effects.count, 0)
    }

    func testEffectUntilEndOfTargetTurn() {
        session.addCombatant(name: "P1", initiative: 20)
        session.addCombatant(name: "P2", initiative: 10)

        let p2Id = session.combatants[1].id
        let effect = Effect(
            name: "Blessed",
            durationType: .untilEndOfTargetTurn(targetID: p2Id)
        )
        session.combatants[0].effects.append(effect)

        // P1's turn ends, P2's begins
        session.nextTurn()

        // Effect still active (expires at end of P2's turn, not start)
        XCTAssertEqual(session.combatants[0].effects.count, 1)

        // P2's turn ends, back to P1
        session.nextTurn()

        // Effect now expired
        XCTAssertEqual(session.combatants[0].effects.count, 0)
    }

    func testMultipleEffectsDifferentDurations() {
        session.addCombatant(name: "P1", initiative: 20)
        session.addCombatant(name: "P2", initiative: 10)

        let p2Id = session.combatants[1].id

        let effect1 = Effect(name: "E1", durationType: .untilStartOfTheirTurn)
        let effect2 = Effect(name: "E2", durationType: .untilEndOfTheirTurn)
        let effect3 = Effect(name: "E3", durationType: .untilStartOfTargetTurn(targetID: p2Id))

        session.combatants[0].effects.append(contentsOf: [effect1, effect2, effect3])
        XCTAssertEqual(session.combatants[0].effects.count, 3)

        // Advance turns: P1's turn ends (triggers E2), P2's turn starts (triggers E3)
        session.nextTurn()

        // E2 (end of P1's turn) and E3 (start of target P2's turn) expire; E1 (start of P1's turn) remains
        XCTAssertEqual(session.combatants[0].effects.count, 1)
        XCTAssertEqual(session.combatants[0].effects.first?.name, "E1")
    }
}

final class CombatantTests: XCTestCase {
    func testCombatantInitialization() {
        let combatant = Combatant(name: "Rogue", initiative: 18)

        XCTAssertEqual(combatant.name, "Rogue")
        XCTAssertEqual(combatant.initiative, 18)
        XCTAssertFalse(combatant.reactionUsed)
        XCTAssertTrue(combatant.effects.isEmpty)
    }

    func testCombatantIDUniqueness() {
        let p1 = Combatant(name: "P1", initiative: 10)
        let p2 = Combatant(name: "P2", initiative: 10)

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
