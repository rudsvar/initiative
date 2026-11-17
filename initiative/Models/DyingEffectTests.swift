import XCTest
@testable import initiative

/// Dying is an effect: its tally lives on a Dying effect, and the combatant's
/// `deathSaves` reads and writes through it.
final class DyingEffectTests: XCTestCase {

    func testSettingDeathSavesAddsADyingEffect() {
        var combatant = Combatant(name: "Wren", initiative: 10, maxHP: 10, isPlayer: true)
        combatant.deathSaves = DeathSaves(successes: 1, failures: 2)
        let dying = combatant.effects.first { $0.name == "Dying" }
        XCTAssertNotNil(dying)
        XCTAssertEqual(dying?.deathSaves, DeathSaves(successes: 1, failures: 2))
        XCTAssertEqual(combatant.deathSaves, DeathSaves(successes: 1, failures: 2))
    }

    func testClearingDeathSavesRemovesTheDyingEffect() {
        var combatant = Combatant(name: "Wren", initiative: 10, maxHP: 10, isPlayer: true)
        combatant.deathSaves = DeathSaves()
        combatant.deathSaves = nil
        XCTAssertFalse(combatant.effects.contains { $0.deathSaves != nil })
        XCTAssertNil(combatant.deathSaves)
    }

    func testUpdatingTheTallyKeepsOneDyingEffect() {
        var combatant = Combatant(name: "Wren", initiative: 10, maxHP: 10, isPlayer: true)
        combatant.deathSaves = DeathSaves()
        combatant.deathSaves = DeathSaves(successes: 2, failures: 0)
        XCTAssertEqual(combatant.effects.filter { $0.deathSaves != nil }.count, 1)
    }

    /// A save from before the Dying effect carried the tally on the combatant itself.
    func testSavedCombatantWithTheOldTallyMovesItOntoADyingEffect() throws {
        let json = """
        {"id":"\(UUID().uuidString)","name":"Wren","initiative":12,"effects":[],
         "deathSaves":{"successes":1,"failures":1}}
        """.data(using: .utf8)!
        let combatant = try JSONDecoder().decode(Combatant.self, from: json)
        XCTAssertEqual(combatant.deathSaves, DeathSaves(successes: 1, failures: 1))
        XCTAssertTrue(combatant.effects.contains { $0.name == "Dying" })
    }

    func testCriticalFailureCountsTwoFailures() {
        var saves = DeathSaves()
        saves.recordCriticalFailure()
        XCTAssertEqual(saves.failures, 2)
        XCTAssertFalse(saves.isDead)
        saves.recordCriticalFailure()
        XCTAssertTrue(saves.isDead)
    }

    /// The detail screen lists custom effects with a remove button and an editor.
    /// Dying is not one of them: removing it would drop the tally, and editing it
    /// would give it a roll of its own on top of the death save.
    func testDyingIsNotListedAsACustomEffect() {
        var combatant = Combatant(name: "Wren", initiative: 10, maxHP: 10, isPlayer: true)
        combatant.deathSaves = DeathSaves()
        combatant.effects.append(Effect(name: "Hexed", durationType: .untilRemoved))
        combatant.effects.append(Effect(name: "Prone", durationType: .untilRemoved))
        XCTAssertEqual(combatant.customEffects.map(\.name), ["Hexed"])
    }
}
