import XCTest
@testable import initiative

/// On Alpha's turn, an effect put on someone else was most likely Alpha's doing,
/// often a spell Alpha now concentrates on. The app offers to mark that; it never
/// does it on its own.
final class ConcentrationSuggestionTests: XCTestCase {
    private func session() -> CombatSession {
        let session = CombatSession()
        session.addCombatant(name: "Alpha", initiative: 20, isPlayer: true)
        session.addCombatant(name: "Goblin", initiative: 10)
        return session
    }

    private func id(_ name: String, _ session: CombatSession) -> UUID { session.combatants.first { $0.name == name }!.id }

    private let frightened = Effect(name: "Frightened", durationType: .untilRemoved)

    func testAConditionOnSomeoneElseSuggestsTheCurrentCombatant() {
        let session = session()
        let suggestion = session.concentrationSuggestion(forAdding: frightened, to: id("Goblin", session))
        XCTAssertEqual(suggestion?.casterID, id("Alpha", session))
        XCTAssertEqual(suggestion?.question, "Is Alpha concentrating on Frightened?")
    }

    func testNothingIsSuggestedForAnEffectOnTheCurrentCombatantItself() {
        let session = session()
        XCTAssertNil(session.concentrationSuggestion(forAdding: frightened, to: id("Alpha", session)))
    }

    func testNothingIsSuggestedWhenTheCurrentCombatantIsAlreadyConcentrating() {
        let session = session()
        session.toggleConcentration(for: id("Alpha", session))
        XCTAssertNil(session.concentrationSuggestion(forAdding: frightened, to: id("Goblin", session)))
    }

    func testNothingIsSuggestedForACooldown() {
        let session = session()
        let recharge = Effect(name: "Breath Weapon", durationType: .untilRemoved, kind: .cooldown)
        XCTAssertNil(session.concentrationSuggestion(forAdding: recharge, to: id("Goblin", session)))
    }

    func testAcceptingMarksTheCasterConcentratingAndLogsIt() {
        let session = session()
        let suggestion = session.concentrationSuggestion(forAdding: frightened, to: id("Goblin", session))!
        session.accept(suggestion)
        XCTAssertTrue(session.combatants.first { $0.name == "Alpha" }!.isConcentrating)
        XCTAssertTrue(session.log.contains { $0.text == "Alpha started concentrating on Frightened" })
    }
}
