import XCTest
@testable import initiative

/// A countable resource — Legendary Actions, "3/day" — spent down over the
/// fight and refilled when the round turns over, unlike `Reaction` which
/// refills on the owner's own turn. See `LimitedUse`.
final class LimitedUseTests: XCTestCase {

    private func session() -> (CombatSession, UUID) {
        let session = CombatSession()
        session.addCombatant(name: "Ancient Dragon", initiative: 20)
        return (session, session.combatants[0].id)
    }

    func testAddingCreatesAFullyChargedResource() {
        let (session, id) = session()

        session.addLimitedUse(name: "Legendary Actions", total: 3, to: id)

        let use = session.combatants[0].limitedUses[0]
        XCTAssertEqual(use.name, "Legendary Actions")
        XCTAssertEqual(use.total, 3)
        XCTAssertEqual(use.remaining, 3)
    }

    func testUsingSpendsOne() {
        let (session, id) = session()
        session.addLimitedUse(name: "Legendary Actions", total: 3, to: id)
        let useID = session.combatants[0].limitedUses[0].id

        session.useLimitedUse(useID, on: id)

        XCTAssertEqual(session.combatants[0].limitedUses[0].remaining, 2)
    }

    func testUsingAnExhaustedResourceDoesNothing() {
        let (session, id) = session()
        session.addLimitedUse(name: "Legendary Actions", total: 1, to: id)
        let useID = session.combatants[0].limitedUses[0].id
        session.useLimitedUse(useID, on: id)

        session.useLimitedUse(useID, on: id)

        XCTAssertEqual(session.combatants[0].limitedUses[0].remaining, 0)
    }

    /// The whole point of tracking this per-round rather than per-own-turn like
    /// `Reaction`: a Legendary Action budget is meant to be spent across every
    /// other combatant's turn, so it can't refill until the round is actually over.
    func testRefillsWhenTheRoundTurnsOverNotOnItsOwnTurn() {
        let (session, id) = session()
        session.addCombatant(name: "Wren", initiative: 10)
        session.addLimitedUse(name: "Legendary Actions", total: 3, to: id)
        let useID = session.combatants.first { $0.id == id }!.limitedUses[0].id
        session.useLimitedUse(useID, on: id)

        session.nextTurn() // Wren's turn starts — same round, shouldn't refill
        XCTAssertEqual(session.combatants.first { $0.id == id }!.limitedUses[0].remaining, 2)

        session.nextTurn() // wraps back to the dragon — round 2 begins
        XCTAssertEqual(session.combatants.first { $0.id == id }!.limitedUses[0].remaining, 3)
    }

    func testUpdatingChangesNameAndCount() {
        let (session, id) = session()
        session.addLimitedUse(name: "Legendary Actions", total: 3, to: id)
        var use = session.combatants[0].limitedUses[0]
        use.name = "Mythic Actions"
        use.total = 5

        session.updateLimitedUse(use, on: id)

        XCTAssertEqual(session.combatants[0].limitedUses[0].name, "Mythic Actions")
        XCTAssertEqual(session.combatants[0].limitedUses[0].total, 5)
    }

    /// Shrinking the count can't leave more uses remaining than now exist.
    func testUpdatingClampsRemainingToTheNewTotal() {
        let (session, id) = session()
        session.addLimitedUse(name: "Legendary Actions", total: 3, to: id)
        var use = session.combatants[0].limitedUses[0]
        use.total = 1

        session.updateLimitedUse(use, on: id)

        XCTAssertEqual(session.combatants[0].limitedUses[0].remaining, 1)
    }

    func testRemoving() {
        let (session, id) = session()
        session.addLimitedUse(name: "Legendary Actions", total: 3, to: id)
        let useID = session.combatants[0].limitedUses[0].id

        session.removeLimitedUse(useID, from: id)

        XCTAssertTrue(session.combatants[0].limitedUses.isEmpty)
    }

    func testPreviousTurnRestoresASpentUse() {
        let (session, id) = session()
        session.addCombatant(name: "Wren", initiative: 10)
        session.addLimitedUse(name: "Legendary Actions", total: 3, to: id)
        let useID = session.combatants.first { $0.id == id }!.limitedUses[0].id
        session.useLimitedUse(useID, on: id)
        session.nextTurn()

        session.previousTurn()

        XCTAssertEqual(session.combatants.first { $0.id == id }!.limitedUses[0].remaining, 2)
    }
}
