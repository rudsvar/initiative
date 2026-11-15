import Foundation
@testable import initiative

/// Test-only combats. Each one is named for the rule it checks, so a failing test
/// names the rule that broke. They are built with the session's own methods, the
/// way a DM builds a fight, so the tests read real state, not hand-made copies.
enum TestCombats {

    /// A goblin at 0 HP sits between two living goblins. Its turn must be passed over.
    static func deadCreatureIsSkipped() -> CombatSession {
        let session = CombatSession()
        session.addCombatant(name: "Alpha", initiative: 20, maxHP: 7)
        session.addCombatant(name: "Fallen", initiative: 15, maxHP: 7)
        session.addCombatant(name: "Omega", initiative: 10, maxHP: 7)
        let fallen = session.combatants.first { $0.name == "Fallen" }!.id
        _ = session.applyDamage(to: fallen, amount: 7)
        return session
    }

    /// A character whose death saves have failed is dead. Its turn is passed over.
    static func failedDeathSavesAreSkipped() -> CombatSession {
        let session = CombatSession()
        session.addCombatant(name: "Alpha", initiative: 20, maxHP: 10)
        session.addCombatant(name: "Wren", initiative: 15, maxHP: 10, isPlayer: true)
        session.addCombatant(name: "Omega", initiative: 10, maxHP: 10)
        let index = session.combatants.firstIndex { $0.name == "Wren" }!
        var saves = DeathSaves()
        for _ in 0..<DeathSaves.required { saves.record(success: false) }
        session.combatants[index].deathSaves = saves
        return session
    }

    /// A character still rolling death saves is dying, not dead. It keeps its turns.
    static func dyingCharacterKeepsItsTurns() -> CombatSession {
        let session = CombatSession()
        session.addCombatant(name: "Alpha", initiative: 20, maxHP: 10)
        session.addCombatant(name: "Wren", initiative: 15, maxHP: 10, isPlayer: true)
        let index = session.combatants.firstIndex { $0.name == "Wren" }!
        session.combatants[index].deathSaves = DeathSaves()
        return session
    }

    /// Everyone but the current combatant is dead. The turn stays with the one
    /// still standing, and the round still advances.
    static func lastStandingKeepsTheTurn() -> CombatSession {
        let session = CombatSession()
        session.addCombatant(name: "Alpha", initiative: 20, maxHP: 7)
        session.addCombatant(name: "Omega", initiative: 10, maxHP: 7)
        let omega = session.combatants.first { $0.name == "Omega" }!.id
        _ = session.applyDamage(to: omega, amount: 7)
        return session
    }
}
