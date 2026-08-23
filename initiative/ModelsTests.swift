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

    // MARK: - Round Tracking

    func testRoundStartsAtOne() {
        session.addCombatant(name: "P1", initiative: 10)
        XCTAssertEqual(session.roundNumber, 1)
    }

    func testRoundIncrementsWhenTurnWrapsToFirstCombatant() {
        session.addCombatant(name: "P1", initiative: 20)
        session.addCombatant(name: "P2", initiative: 10)

        session.nextTurn() // P1 -> P2, still round 1
        XCTAssertEqual(session.roundNumber, 1)

        session.nextTurn() // P2 -> P1 (wraps), round 2
        XCTAssertEqual(session.roundNumber, 2)
    }

    func testPreviousTurnRevertsRoundNumber() {
        session.addCombatant(name: "P1", initiative: 20)
        session.addCombatant(name: "P2", initiative: 10)
        session.nextTurn()
        session.nextTurn() // now round 2

        session.previousTurn()

        XCTAssertEqual(session.roundNumber, 1)
    }

    func testResetRestartsRoundAtOne() {
        session.addCombatant(name: "P1", initiative: 20)
        session.nextTurn()
        session.nextTurn()

        session.reset()

        XCTAssertEqual(session.roundNumber, 1)
    }

    func testRoundNumberPersistsThroughSaveAndLoad() {
        session.addCombatant(name: "P1", initiative: 20)
        session.addCombatant(name: "P2", initiative: 10)
        session.nextTurn()
        session.nextTurn() // round 2
        let record = session.makeRecord()

        session.reset()
        session.load(record)

        XCTAssertEqual(session.roundNumber, 2)
    }

    // MARK: - Session Rename

    func testRenameSessionUpdatesName() {
        session.name = "Goblin Ambush"
        XCTAssertEqual(session.name, "Goblin Ambush")
    }

    func testRenameSessionTrimsWhitespace() {
        session.name = "  Goblin Ambush  "
        XCTAssertEqual(session.name, "Goblin Ambush")
    }

    func testRenameSessionIgnoresBlankName() {
        let original = session.name
        session.name = "   "
        XCTAssertEqual(session.name, original)
    }

    // MARK: - Remove Combatant

    func testRemoveCombatant() {
        session.addCombatant(name: "P1", initiative: 20)
        session.addCombatant(name: "P2", initiative: 10)
        let idToRemove = session.combatants[1].id

        session.removeCombatant(id: idToRemove)

        XCTAssertEqual(session.combatants.count, 1)
        XCTAssertEqual(session.combatants.first?.name, "P1")
    }

    func testRemoveCombatantBeforeCurrentTurnShiftsIndexBack() {
        session.addCombatant(name: "P1", initiative: 20)
        session.addCombatant(name: "P2", initiative: 10)
        session.addCombatant(name: "P3", initiative: 5)
        session.nextTurn() // current is now P2 (index 1)
        let p2Id = session.combatants[1].id
        XCTAssertEqual(session.currentCombatant?.id, p2Id)

        let p1Id = session.combatants[0].id
        session.removeCombatant(id: p1Id)

        // P2 shifted to index 0; currentTurnIndex must follow it
        XCTAssertEqual(session.currentCombatant?.id, p2Id)
    }

    func testRemoveCombatantClearsHistory() {
        session.addCombatant(name: "P1", initiative: 20)
        session.addCombatant(name: "P2", initiative: 10)
        session.nextTurn()
        XCTAssertTrue(session.canGoToPreviousTurn)

        session.removeCombatant(id: session.combatants[0].id)

        XCTAssertFalse(session.canGoToPreviousTurn)
    }

    func testRemoveNonexistentCombatantDoesNothing() {
        session.addCombatant(name: "P1", initiative: 20)
        session.removeCombatant(id: UUID())
        XCTAssertEqual(session.combatants.count, 1)
    }

    // MARK: - Initiative Bonus

    func testAddCombatantWithNilInitiativeAppliesBonusToRoll() {
        // Roll is random 1...20, so assert the bonus's effect on the floor/ceiling
        // rather than an exact value: with bonus +5, result must be in 6...25.
        session.addCombatant(name: "Goblin", initiative: nil, initiativeBonus: 5)
        let rolled = session.combatants[0].initiative
        XCTAssertTrue((6...25).contains(rolled), "expected roll+bonus in 6...25, got \(rolled)")
    }

    func testAddCombatantWithExplicitInitiativeIgnoresBonus() {
        session.addCombatant(name: "Goblin", initiative: 10, initiativeBonus: 5)
        XCTAssertEqual(session.combatants[0].initiative, 10, "explicit value should not have the bonus applied")
    }

    func testAddCombatantsAppliesBonusToEveryIndependentRoll() {
        session.addCombatants(name: "Goblin", initiative: nil, maxHP: nil, count: 5, initiativeBonus: 5)
        let initiatives = session.combatants.map { $0.initiative }
        XCTAssertTrue(initiatives.allSatisfy { (6...25).contains($0) })
    }

    // MARK: - HP Tracking

    func testAddCombatantWithMaxHPSetsCurrentHPToMax() {
        session.addCombatant(name: "Goblin", initiative: 10, maxHP: 7)
        XCTAssertEqual(session.combatants[0].maxHP, 7)
        XCTAssertEqual(session.combatants[0].currentHP, 7)
    }

    func testAddCombatantWithoutMaxHPLeavesHPUntracked() {
        session.addCombatant(name: "Goblin", initiative: 10)
        XCTAssertNil(session.combatants[0].maxHP)
        XCTAssertNil(session.combatants[0].currentHP)
        XCTAssertFalse(session.combatants[0].isDead)
    }

    func testEnableHPTrackingSetsMaxAndCurrent() {
        session.addCombatant(name: "Goblin", initiative: 10)
        let id = session.combatants[0].id

        session.enableHPTracking(for: id, maxHP: 12)

        XCTAssertEqual(session.combatants[0].maxHP, 12)
        XCTAssertEqual(session.combatants[0].currentHP, 12)
    }

    func testEnableHPTrackingIgnoresNonPositiveMaxHP() {
        session.addCombatant(name: "Goblin", initiative: 10)
        let id = session.combatants[0].id

        session.enableHPTracking(for: id, maxHP: 0)

        XCTAssertNil(session.combatants[0].maxHP)
    }

    func testApplyDamageReducesCurrentHP() {
        session.addCombatant(name: "Goblin", initiative: 10, maxHP: 10)
        let id = session.combatants[0].id

        session.applyDamage(to: id, amount: 4)

        XCTAssertEqual(session.combatants[0].currentHP, 6)
    }

    func testApplyDamageClampsAtZero() {
        session.addCombatant(name: "Goblin", initiative: 10, maxHP: 10)
        let id = session.combatants[0].id

        session.applyDamage(to: id, amount: 999)

        XCTAssertEqual(session.combatants[0].currentHP, 0)
        XCTAssertTrue(session.combatants[0].isDead)
    }

    func testApplyDamageOnUntrackedCombatantDoesNothing() {
        session.addCombatant(name: "Goblin", initiative: 10)
        let id = session.combatants[0].id

        session.applyDamage(to: id, amount: 5)

        XCTAssertNil(session.combatants[0].currentHP)
    }

    func testApplyHealingRestoresCurrentHP() {
        session.addCombatant(name: "Goblin", initiative: 10, maxHP: 10)
        let id = session.combatants[0].id
        session.applyDamage(to: id, amount: 7)

        session.applyHealing(to: id, amount: 3)

        XCTAssertEqual(session.combatants[0].currentHP, 6)
    }

    func testApplyHealingClampsAtMaxHP() {
        session.addCombatant(name: "Goblin", initiative: 10, maxHP: 10)
        let id = session.combatants[0].id
        session.applyDamage(to: id, amount: 2)

        session.applyHealing(to: id, amount: 999)

        XCTAssertEqual(session.combatants[0].currentHP, 10)
    }

    func testDeadCombatantRevivedByHealingIsNoLongerDead() {
        session.addCombatant(name: "Goblin", initiative: 10, maxHP: 10)
        let id = session.combatants[0].id
        session.applyDamage(to: id, amount: 10)
        XCTAssertTrue(session.combatants[0].isDead)

        session.applyHealing(to: id, amount: 5)

        XCTAssertFalse(session.combatants[0].isDead)
        XCTAssertEqual(session.combatants[0].currentHP, 5)
    }

    func testIncreaseMaxHPRaisesBothMaxAndCurrent() {
        session.addCombatant(name: "Goblin", initiative: 10, maxHP: 10)
        let id = session.combatants[0].id
        session.applyDamage(to: id, amount: 4) // current 6/10

        session.increaseMaxHP(for: id, amount: 5)

        XCTAssertEqual(session.combatants[0].maxHP, 15)
        XCTAssertEqual(session.combatants[0].currentHP, 11)
    }

    func testIncreaseMaxHPOnUntrackedCombatantDoesNothing() {
        session.addCombatant(name: "Goblin", initiative: 10)
        let id = session.combatants[0].id

        session.increaseMaxHP(for: id, amount: 5)

        XCTAssertNil(session.combatants[0].maxHP)
    }

    func testIncreaseMaxHPIgnoresNonPositiveAmount() {
        session.addCombatant(name: "Goblin", initiative: 10, maxHP: 10)
        let id = session.combatants[0].id

        session.increaseMaxHP(for: id, amount: 0)
        session.increaseMaxHP(for: id, amount: -3)

        XCTAssertEqual(session.combatants[0].maxHP, 10)
    }

    func testIncreaseMaxHPCanReviveADeadCombatant() {
        session.addCombatant(name: "Goblin", initiative: 10, maxHP: 10)
        let id = session.combatants[0].id
        session.applyDamage(to: id, amount: 10)
        XCTAssertTrue(session.combatants[0].isDead)

        session.increaseMaxHP(for: id, amount: 5)

        XCTAssertFalse(session.combatants[0].isDead)
        XCTAssertEqual(session.combatants[0].currentHP, 5)
    }

    func testAddCombatantsSpawnsCountWithNumberedNames() {
        session.addCombatants(name: "Goblin", initiative: nil, maxHP: 5, count: 3)

        let goblins = session.combatants.filter { $0.name.hasPrefix("Goblin") }
        XCTAssertEqual(goblins.count, 3)
        XCTAssertEqual(Set(goblins.map { $0.name }), ["Goblin 1", "Goblin 2", "Goblin 3"])
        XCTAssertTrue(goblins.allSatisfy { $0.maxHP == 5 && $0.currentHP == 5 })
    }

    func testAddCombatantsWithCountGreaterThanOneIgnoresExplicitInitiative() {
        // A shared initiative across multiple spawned copies wouldn't make sense --
        // count > 1 always rolls independently per copy, even if a value was given.
        session.addCombatants(name: "Goblin", initiative: 15, maxHP: nil, count: 5)

        let initiatives = session.combatants.map { $0.initiative }
        XCTAssertFalse(initiatives.allSatisfy { $0 == 15 }, "expected independent random rolls, not all 15")
    }

    func testAddCombatantsWithCountOneUsesUnsuffixedNameAndGivenInitiative() {
        session.addCombatants(name: "Goblin", initiative: 15, maxHP: nil, count: 1)

        XCTAssertEqual(session.combatants[0].name, "Goblin")
        XCTAssertEqual(session.combatants[0].initiative, 15)
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
