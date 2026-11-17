#if DEBUG
import Foundation

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
        _ = session.applyDamage(to: session.combatants.first { $0.name == "Wren" }!.id, amount: 10)
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

    /// Buffs are marked on the roster, with the amounts only on the detail screen.
    /// Wren has 5 temporary HP and 2 temporary AC: 27/22 and AC 16, both bold
    /// green. The ogre's max HP went up by 4 (bold green max), the goblin's down by
    /// 2 (bold red max). No "+N" under any number.
    static func buffsAreMarkedOnTheRoster() -> CombatSession {
        let session = CombatSession()
        session.addCombatant(name: "Wren", initiative: 15, maxHP: 22, armorClass: 14, isPlayer: true)
        session.addCombatant(name: "Ogre", initiative: 12, maxHP: 59, armorClass: 11)
        session.addCombatant(name: "Goblin", initiative: 10, maxHP: 7, armorClass: 15)
        let id = { name in session.combatants.first { $0.name == name }!.id }
        session.grantTemporaryHP(to: id("Wren"), amount: 5)
        session.grantTemporaryAC(to: id("Wren"), amount: 2)
        session.increaseMaxHP(for: id("Ogre"), amount: 4)
        session.decreaseMaxHP(for: id("Goblin"), amount: 2)
        return session
    }

    /// Wren is Invisible and it's her turn: Next asks "Did Wren attack, deal damage
    /// or cast a spell?". Yes ends Invisible, No keeps it. The goblin is Greater
    /// Invisible and is never asked.
    static func invisibleAsksAtTurnEnd() -> CombatSession {
        let session = CombatSession()
        session.addCombatant(name: "Wren", initiative: 20, maxHP: 22, armorClass: 14, isPlayer: true)
        session.addCombatant(name: "Goblin", initiative: 10, maxHP: 7, armorClass: 15)
        session.combatants[0].effects.append(Effect(name: "Invisible", durationType: .untilRemoved))
        session.combatants[1].effects.append(Effect(name: "Greater Invisible", durationType: .untilEndOfTheirTurn(remainingTurns: 10)))
        return session
    }

    /// It's Alpha's turn. Open the goblin and tap Frightened: the app asks "Is Alpha
    /// concentrating on Frightened?". Concentrating puts Alpha's concentration
    /// chip on, on the combatant screen and in Alpha's roster row. Tapping a
    /// condition on Alpha itself asks nothing. Next from the frightened goblin
    /// asks its save with the marker still on the goblin.
    static func concentrationIsOffered() -> CombatSession {
        let session = CombatSession()
        session.addCombatant(name: "Alpha", initiative: 20, maxHP: 22, armorClass: 14, isPlayer: true)
        session.addCombatant(name: "Goblin", initiative: 10, maxHP: 7, armorClass: 15)
        return session
    }

    /// Alpha and Omega, both at 20 HP and AC 14. Changes to them show beside their
    /// numbers until their own turn starts.
    static func hpAndACChangesShowUntilTurnStarts() -> CombatSession {
        let session = CombatSession()
        session.addCombatant(name: "Alpha", initiative: 20, maxHP: 20, armorClass: 14)
        session.addCombatant(name: "Omega", initiative: 10, maxHP: 20, armorClass: 14)
        return session
    }

    /// A Wolf (SRD stat block) at 7 of 11 HP, AC 12 lowered by 2: checks the stat facts
    /// in the top box, the HP and AC changes beside their numbers, and the colours.
    static func wolfWithChanges() -> CombatSession {
        let session = CombatSession()
        session.addCombatant(name: "Wolf", initiative: 12, maxHP: 11, armorClass: 12)
        let wolf = session.combatants[0].id
        _ = session.applyDamage(to: wolf, amount: 4)
        session.adjustArmorClass(for: wolf, by: -2)
        return session
    }

    /// Wren is burning and holding concentration. Next from Alpha asks for her Burning
    /// damage (type a number); after it, a concentration check is asked.
    static func burningAtStartOfTurn() -> CombatSession {
        let session = CombatSession()
        session.addCombatant(name: "Alpha", initiative: 20, maxHP: 12)
        session.addCombatant(name: "Wren", initiative: 10, maxHP: 20, armorClass: 14, isPlayer: true)
        let wren = session.combatants.firstIndex { $0.name == "Wren" }!
        session.combatants[wren].effects.append(Effect(name: "Burning", durationType: .untilRemoved))
        session.combatants[wren].isConcentrating = true
        return session
    }

    /// Wren is dying with two successes and one failure, and AC 14: checks the tally beside her name and her AC.
    static func dyingWithTally() -> CombatSession {
        let session = CombatSession()
        session.addCombatant(name: "Wren", initiative: 12, maxHP: 10, armorClass: 14, isPlayer: true)
        _ = session.applyDamage(to: session.combatants[0].id, amount: 10)
        session.combatants[0].deathSaves = DeathSaves(successes: 2, failures: 1)
        return session
    }

    /// Alpha acts first; Wren is dying, so her start-of-turn death save is owed when
    /// Alpha's turn ends. Next opens the prompt and the marker moves to Wren; Cancel
    /// puts it back on Alpha.
    static func startOfTurnPromptMovesTheMarker() -> CombatSession {
        let session = CombatSession()
        session.addCombatant(name: "Alpha", initiative: 20, maxHP: 10)
        session.addCombatant(name: "Wren", initiative: 10, maxHP: 10, isPlayer: true)
        _ = session.applyDamage(to: session.combatants.first { $0.name == "Wren" }!.id, amount: 10)
        return session
    }

    /// Alpha has HP tracked; Gamma has none (shows −/−). Checks kill, revive, the swipes
    /// and Previous undoing them.
    static func killAndReviveAreUndoable() -> CombatSession {
        let session = CombatSession()
        session.addCombatant(name: "Alpha", initiative: 20, maxHP: 7)
        session.addCombatant(name: "Gamma", initiative: 10)
        return session
    }

    /// A character with an armor class and no buffers, for armor class tests.
    static func wrenWithArmorClass() -> CombatSession {
        let session = CombatSession()
        session.addCombatant(name: "Wren", initiative: 12, maxHP: 10, armorClass: 14, isPlayer: true)
        return session
    }
}

extension TestCombats {
    /// Every scenario, by the name used on the command line: `-scenario <name>`.
    static let scenarios: [String: () -> CombatSession] = [
        "deadCreatureIsSkipped": deadCreatureIsSkipped,
        "failedDeathSavesAreSkipped": failedDeathSavesAreSkipped,
        "dyingCharacterKeepsItsTurns": dyingCharacterKeepsItsTurns,
        "lastStandingKeepsTheTurn": lastStandingKeepsTheTurn,
        "wrenWithArmorClass": wrenWithArmorClass,
        "buffsAreMarkedOnTheRoster": buffsAreMarkedOnTheRoster,
        "invisibleAsksAtTurnEnd": invisibleAsksAtTurnEnd,
        "concentrationIsOffered": concentrationIsOffered,
        "hpAndACChangesShowUntilTurnStarts": hpAndACChangesShowUntilTurnStarts,
        "wolfWithChanges": wolfWithChanges,
        "dyingWithTally": dyingWithTally,
        "burningAtStartOfTurn": burningAtStartOfTurn,
        "killAndReviveAreUndoable": killAndReviveAreUndoable,
        "startOfTurnPromptMovesTheMarker": startOfTurnPromptMovesTheMarker,
    ]
}
#endif
