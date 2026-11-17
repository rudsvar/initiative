import XCTest
@testable import initiative

/// Burning hurts at the start of the burning combatant's own turn. The app asks for
/// the number (the DM rolls it) and applies it as ordinary damage.
final class BurningTests: XCTestCase {
    private func session() -> CombatSession {
        let session = CombatSession()
        session.addCombatant(name: "Dragon", initiative: 20)
        session.addCombatant(name: "Wren", initiative: 10, maxHP: 20, isPlayer: true)
        let wren = session.combatants.firstIndex { $0.name == "Wren" }!
        session.combatants[wren].effects.append(Effect(name: "Burning", durationType: .untilRemoved))
        return session
    }

    private var wren: (CombatSession) -> Combatant { { $0.combatants.first { $0.name == "Wren" }! } }

    private func damagePrompt(_ session: CombatSession) -> TurnPrompt? {
        session.pendingTurnPrompts().first { if case .damage = $0.subject { true } else { false } }
    }

    func testTheBurningCombatantIsAskedForDamageWhenItsTurnIsAboutToStart() {
        let session = session()
        let prompt = damagePrompt(session)
        XCTAssertEqual(prompt?.combatantName, "Wren")
        XCTAssertEqual(prompt?.hint, "1d4 fire")
    }

    func testNoDamageIsAskedOnTheTurnBeforeOrOfSomeoneElse() {
        let session = session()
        session.nextTurn()   // Wren's turn now; the next to start is Dragon
        XCTAssertNil(damagePrompt(session))
    }

    func testTheEnteredAmountIsTakenAsDamageAndBurningStays() {
        let session = session()
        let prompt = damagePrompt(session)!
        session.nextTurn(resolving: [prompt: .success], damage: [prompt: 3])
        XCTAssertEqual(wren(session).currentHP, 17)
        XCTAssertEqual(wren(session).recentHPChange, -3)
        XCTAssertTrue(wren(session).effects.contains { $0.name == "Burning" })
        XCTAssertTrue(session.log.contains { $0.text.contains("took 3 damage") })
    }

    func testNoDamageLeavesHitPointsAlone() {
        let session = session()
        let prompt = damagePrompt(session)!
        session.nextTurn(resolving: [prompt: .failure], damage: [:])
        XCTAssertEqual(wren(session).currentHP, 20)
    }

    func testPreviousRestoresTheHitPoints() {
        let session = session()
        let prompt = damagePrompt(session)!
        session.nextTurn(resolving: [prompt: .success], damage: [prompt: 4])
        session.previousTurn()
        XCTAssertEqual(wren(session).currentHP, 20)
    }

    func testDamageThatThreatensConcentrationAsksForTheCheck() {
        let session = session()
        let index = session.combatants.firstIndex { $0.name == "Wren" }!
        session.combatants[index].isConcentrating = true
        let prompt = damagePrompt(session)!
        let followUp = session.nextTurn(resolving: [prompt: .success], damage: [prompt: 2])
        XCTAssertEqual(followUp.map(\.subject), [.concentration])
    }

    /// Effect names are matched without regard to case everywhere else, and a
    /// hand-typed "burning" is the same condition.
    func testATypedBurningInAnyCaseAsksForDamage() {
        let session = CombatSession()
        session.addCombatant(name: "Dragon", initiative: 20)
        session.addCombatant(name: "Wren", initiative: 10, maxHP: 20, isPlayer: true)
        let wren = session.combatants.firstIndex { $0.name == "Wren" }!
        session.combatants[wren].effects.append(Effect(name: "burning", durationType: .untilRemoved))
        XCTAssertNotNil(damagePrompt(session))
    }
}
