import Foundation

/// One run of combat: the roster, whose turn it is, the round counter, and the
/// event log — the app's single mutable domain object, owned by `RootView` and
/// passed down to every screen.
///
/// Two design decisions shape most of what's below. First, **the log is the
/// undo mechanism for HP**: damage/heal/max-increase each append a structured
/// `HPOperation`, and deleting one of those entries recomputes that combatant's
/// HP by replaying the rest, so there's no separate undo stack to keep in sync.
/// Second, **anything that expires does so as an `Effect`** — including the
/// "reaction used" marker, which is an ordinary internal effect rather than a
/// stored flag, so it ages out through `removeExpiredEffects` like everything
/// else instead of needing its own reset step in `nextTurn()`.
///
/// Deliberately kept as one type in one file rather than split across
/// extensions: `history` and `log` are `private`, and Swift's file-scoped
/// `private` means splitting into per-concern files would mean widening them to
/// `internal` — trading real encapsulation for navigability. The `MARK` sections
/// buy the navigability instead.
@Observable
class CombatSession {
    var combatants: [Combatant] = []
    var currentTurnIndex: Int = 0
    var roundNumber: Int = 1
    private(set) var log: [LogEntry] = []

    /// Effects belonging to the fight rather than to any creature in it — a
    /// collapsing bridge, an environmental hazard, anything that fires at the top
    /// of the round.
    ///
    /// These live here rather than on a combatant because pinning them to
    /// whichever creature was handy is wrong in a way that bites: the effect
    /// vanishes when that creature dies or is removed, and it fires on their turn
    /// instead of at the top of the round.
    private(set) var roundEffects: [Effect] = []

    /// When true, HP/AC display shows approximate bands instead of exact numbers
    /// (for when the DM's screen is visible to players). A live, per-session UI
    /// mode, not persisted — always starts false (DM view) on load/resume.
    var playerViewEnabled = false

    /// Identity of this session's on-disk record — stable across autosaves so
    /// repeated saves overwrite the same file instead of piling up duplicates.
    private(set) var id = UUID()
    var name: String {
        get { _name }
        set {
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            _name = trimmed
        }
    }
    private var _name = CombatSession.defaultName()

    private var history: [(combatants: [Combatant], roundEffects: [Effect], currentTurnIndex: Int, roundNumber: Int, logCount: Int)] = []

    private func appendLog(_ text: String, combatantId: UUID? = nil, hpOperation: HPOperation? = nil) {
        log.append(LogEntry(text: text, roundNumber: roundNumber, combatantId: combatantId, hpOperation: hpOperation))
    }

    private static func defaultName() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }

    // MARK: - Roster

    var canGoToPreviousTurn: Bool {
        !history.isEmpty
    }

    var currentCombatant: Combatant? {
        guard combatants.indices.contains(currentTurnIndex) else { return nil }
        return combatants[currentTurnIndex]
    }

    /// Highest initiative first; ties keep the order they were in. Stable on
    /// purpose: `Array.sort` is not, and an unstable sort could swap two tied
    /// combatants each time, moving the turn under the DM's feet.
    private func sortByInitiative() {
        combatants = combatants.enumerated()
            .sorted { $0.element.initiative != $1.element.initiative ? $0.element.initiative > $1.element.initiative : $0.offset < $1.offset }
            .map(\.element)
    }

    /// `initiative: nil` rolls 1...20 plus `initiativeBonus` (a flat modifier, e.g. from
    /// a creature preset). An explicit `initiative` value is used exactly as given —
    /// the bonus only applies to random rolls, never on top of a deliberate value.
    func addCombatant(name: String, initiative: Int? = nil, maxHP: Int? = nil, armorClass: Int? = nil, initiativeBonus: Int = 0, isPlayer: Bool = false) {
        let resolvedInitiative = initiative ?? (Int.random(in: 1...20) + initiativeBonus)
        let combatant = Combatant(name: name, initiative: resolvedInitiative, maxHP: maxHP, armorClass: armorClass, isPlayer: isPlayer)
        combatants.append(combatant)
        sortByInitiative()
        appendLog("\(name) added to combat (initiative \(resolvedInitiative))")
        if let maxHP {
            // A separate, structured entry so replayHP has a baseline to replay
            // from even when HP was set at creation time rather than via "Track HP".
            appendLog(
                "\(name) started tracking HP (\(maxHP)/\(maxHP))",
                combatantId: combatant.id,
                hpOperation: .enableTracking(amount: maxHP)
            )
        }
    }

    /// Spawns `count` copies of the same creature. `initiative: nil` rolls each copy
    /// independently (1...20 + initiativeBonus); an explicit `initiative` value is
    /// used as-is for every copy (no per-copy randomization — if you typed a number,
    /// that's what they all get). Names get a numeric suffix ("Goblin 1", "Goblin 2",
    /// ...) when count > 1.
    func addCombatants(name: String, initiative: Int?, maxHP: Int?, armorClass: Int? = nil, count: Int, initiativeBonus: Int = 0, isPlayer: Bool = false) {
        guard count > 0 else { return }
        var spawned: [Combatant] = []
        for i in 1...count {
            let resolvedInitiative = initiative ?? (Int.random(in: 1...20) + initiativeBonus)
            let displayName = count > 1 ? "\(name) \(i)" : name
            spawned.append(Combatant(name: displayName, initiative: resolvedInitiative, maxHP: maxHP, armorClass: armorClass, isPlayer: isPlayer))
        }
        combatants.append(contentsOf: spawned)
        sortByInitiative()
        appendLog(count > 1 ? "\(count)x \(name) added to combat" : "\(name) added to combat")
        if let maxHP {
            // Same reasoning as addCombatant: a structured baseline entry per
            // spawned copy, tied to that copy's own id, so replayHP works.
            for combatant in spawned {
                appendLog(
                    "\(combatant.name) started tracking HP (\(maxHP)/\(maxHP))",
                    combatantId: combatant.id,
                    hpOperation: .enableTracking(amount: maxHP)
                )
            }
        }
    }

    /// Changes a combatant's initiative and moves them to their new place in the
    /// order. The turn in progress stays with whoever has it, even if they moved.
    func setInitiative(_ value: Int, for id: UUID) {
        guard let index = combatants.firstIndex(where: { $0.id == id }),
              combatants[index].initiative != value else { return }
        let current = currentCombatant?.id
        combatants[index].initiative = value
        sortByInitiative()
        if let current, let newIndex = combatants.firstIndex(where: { $0.id == current }) {
            currentTurnIndex = newIndex
        }
        appendLog("\(combatants.first { $0.id == id }!.name)'s initiative changed to \(value)", combatantId: id)
    }

    // MARK: - Health

    func enableHPTracking(for id: UUID, maxHP: Int) {
        guard let index = combatants.firstIndex(where: { $0.id == id }), maxHP > 0 else { return }
        combatants[index].maxHP = maxHP
        combatants[index].currentHP = maxHP
        appendLog(
            "\(combatants[index].name) started tracking HP (\(maxHP)/\(maxHP))",
            combatantId: id,
            hpOperation: .enableTracking(amount: maxHP)
        )
    }

    /// Returns a concentration check when the hit threatened something the
    /// combatant was holding — the one prompt in the app that isn't tied to a
    /// turn boundary, because damage isn't either.
    @discardableResult
    func applyDamage(to id: UUID, amount: Int) -> TurnPrompt? {
        guard amount > 0, let index = combatants.firstIndex(where: { $0.id == id }),
              let current = combatants[index].currentHP else { return nil }

        let before = combatants[index].temporaryHP ?? 0
        let result = Self.absorb(damage: amount, temporaryHP: combatants[index].temporaryHP, currentHP: current)
        combatants[index].temporaryHP = result.temporaryHP
        combatants[index].currentHP = result.currentHP
        noteHPChange(at: index, by: (result.currentHP ?? current) - current)

        let absorbed = before - (result.temporaryHP ?? 0)
        let note = absorbed > 0 ? ", \(absorbed) absorbed" : ""
        appendLog(
            "\(combatants[index].name) took \(amount) damage\(note) (\(result.currentHP)/\(combatants[index].maxHP!) HP)",
            combatantId: id,
            hpOperation: .damage(amount: amount)
        )
        startDyingOrDieIfNeeded(at: index)
        applyDeathConsequences(at: index, hpDamage: amount - absorbed, hpBefore: current)
        return concentrationCheck(at: index, afterTaking: amount)
    }

    /// Damage that carries a player past 0 HP by at least their max HP kills them
    /// outright (massive damage). Damage taken while already at 0 HP is a failed
    /// death save, and breaks a stable creature's stability. Only players have
    /// death saves here; anything else is simply dead at 0.
    static func isMassiveDamage(hpDamage: Int, hpBefore: Int, maxHP: Int) -> Bool {
        hpDamage - hpBefore >= maxHP
    }

    private func applyDeathConsequences(at index: Int, hpDamage: Int, hpBefore: Int) {
        let combatant = combatants[index]
        guard combatant.isPlayer, combatant.currentHP == 0, hpDamage > 0,
              let maxHP = combatant.maxHP, maxHP > 0 else { return }
        if Self.isMassiveDamage(hpDamage: hpDamage, hpBefore: hpBefore, maxHP: maxHP) {
            guard combatants[index].deathSaves?.isDead != true else { return }
            combatants[index].deathSaves = DeathSaves(successes: 0, failures: DeathSaves.required)
            appendLog("\(combatant.name) died outright (massive damage)", combatantId: combatant.id)
            return
        }
        guard hpBefore == 0 else { return }
        var saves = combatants[index].deathSaves ?? DeathSaves()
        if saves.isDead { return }
        if saves.isStable { saves = DeathSaves() }
        saves.record(success: false)
        combatants[index].deathSaves = saves
        appendLog(
            "\(combatant.name) took damage at 0 HP and failed a death save (\(saves.successes) made, \(saves.failures) failed)",
            combatantId: combatant.id
        )
        if saves.isDead { appendLog("\(combatant.name) died", combatantId: combatant.id) }
    }

    /// Splits an incoming hit between the temporary buffer and real hit points.
    ///
    /// Shared by `applyDamage` and `replayHP` deliberately: the live path and
    /// the replay path have to agree exactly or deleting a log entry would
    /// recompute a different answer than the one the DM originally saw, and
    /// keeping them as one function makes that true by construction rather than
    /// by two people remembering.
    static func absorb(damage: Int, temporaryHP: Int?, currentHP: Int) -> (temporaryHP: Int?, currentHP: Int) {
        guard let buffer = temporaryHP, buffer > 0 else {
            return (temporaryHP, max(0, currentHP - damage))
        }
        let absorbed = min(buffer, damage)
        let remaining = buffer - absorbed
        return (remaining > 0 ? remaining : nil, max(0, currentHP - (damage - absorbed)))
    }

    /// Temporary hit points don't stack: a new grant either replaces what is
    /// there or is ignored, whichever is larger (the player's choice by the rules,
    /// and nobody chooses the smaller one). Shared with `recomputeHP`.
    static func grantedTemporaryHP(existing: Int?, new: Int) -> Int {
        Swift.max(existing ?? 0, new)
    }

    func grantTemporaryHP(to id: UUID, amount: Int) {
        guard amount > 0, let index = combatants.firstIndex(where: { $0.id == id }) else { return }
        let existing = combatants[index].temporaryHP ?? 0
        combatants[index].temporaryHP = Self.grantedTemporaryHP(existing: existing, new: amount)
        let text = amount > existing
            ? "\(combatants[index].name) gained \(amount) temporary HP"
            : "\(combatants[index].name) kept \(existing) temporary HP instead of \(amount)"
        appendLog(
            text,
            combatantId: id,
            hpOperation: .grantTemporaryHP(amount: amount)
        )
    }

    /// Grants temporary armor class, replacing any earlier grant, as temporary HP does.
    func grantTemporaryAC(to id: UUID, amount: Int) {
        guard amount > 0, let index = combatants.firstIndex(where: { $0.id == id }) else { return }
        combatants[index].temporaryAC = amount
        appendLog("\(combatants[index].name) gained \(amount) temporary AC", combatantId: id)
    }

    static func concentrationDC(damage: Int) -> Int {
        Swift.max(10, damage / 2)
    }

    /// Damage threatens concentration. Being dropped to 0 ends it outright —
    /// there's nothing to roll for — otherwise the DM is asked.
    private func concentrationCheck(at index: Int, afterTaking amount: Int) -> TurnPrompt? {
        guard combatants[index].isConcentrating else { return nil }
        guard combatants[index].currentHP ?? 0 > 0 else {
            combatants[index].isConcentrating = false
            appendLog("\(combatants[index].name) lost concentration", combatantId: combatants[index].id)
            return nil
        }
        return TurnPrompt(
            id: UUID(),
            combatantID: combatants[index].id,
            combatantName: combatants[index].name,
            subject: .concentration,
            title: "Roll to hold concentration",
            // The DC is 10 or half the damage taken, whichever is higher.
            hint: "Took \(amount) damage, DC \(Self.concentrationDC(damage: amount))",
            deathSaves: nil
        )
    }

    /// Concentration is a bare flag rather than an `Effect` — no name, no
    /// duration, just a thing that's true until damage threatens it or the DM
    /// turns it off by hand.
    func toggleConcentration(for id: UUID) {
        guard let index = combatants.firstIndex(where: { $0.id == id }) else { return }
        combatants[index].isConcentrating.toggle()
        appendLog(
            "\(combatants[index].name) \(combatants[index].isConcentrating ? "started" : "stopped") concentrating",
            combatantId: id
        )
    }

    func applyHealing(to id: UUID, amount: Int) {
        guard amount > 0, let index = combatants.firstIndex(where: { $0.id == id }),
              let current = combatants[index].currentHP,
              let maxHP = combatants[index].maxHP else { return }
        combatants[index].currentHP = min(maxHP, current + amount)
        noteHPChange(at: index, by: combatants[index].currentHP! - current)
        appendLog(
            "\(combatants[index].name) healed \(amount) HP (\(combatants[index].currentHP!)/\(maxHP) HP)",
            combatantId: id,
            hpOperation: .healing(amount: amount)
        )
        clearDeathSavesIfAboveZero(at: index)
    }

    /// A player who hits 0 starts rolling death saves; anything else is simply
    /// dead, exactly as before this existed. That distinction is the entire
    /// reason `Combatant.isPlayer` exists — without it, auto-starting death saves
    /// would put a three-turn clock on every goblin the party kills.
    private func startDyingOrDieIfNeeded(at index: Int) {
        guard combatants[index].currentHP == 0 else { return }
        if combatants[index].isPlayer {
            guard combatants[index].deathSaves == nil else { return }
            combatants[index].deathSaves = DeathSaves()
            appendLog("\(combatants[index].name) is dying", combatantId: combatants[index].id)
        } else if combatants[index].isDead {
            appendLog("\(combatants[index].name) died", combatantId: combatants[index].id)
        }
    }

    /// Any healing above 0 ends the situation outright — including a resolved
    /// tally, so someone who died and was then brought back doesn't stay flagged.
    private func clearDeathSavesIfAboveZero(at index: Int) {
        guard let current = combatants[index].currentHP, current > 0,
              combatants[index].deathSaves != nil else { return }
        combatants[index].deathSaves = nil
        appendLog("\(combatants[index].name) is no longer dying", combatantId: combatants[index].id)
    }

    /// Raises both max and current HP by `amount` (a temporary buff, leveling up,
    /// etc. — the kind of boost that also tops you up, not just a higher ceiling).
    func increaseMaxHP(for id: UUID, amount: Int) {
        guard amount > 0, let index = combatants.firstIndex(where: { $0.id == id }),
              let maxHP = combatants[index].maxHP,
              let current = combatants[index].currentHP else { return }
        combatants[index].maxHP = maxHP + amount
        noteMaxHPChange(at: index, by: amount)
        combatants[index].currentHP = current + amount
        combatants[index].maxHPIncreased = true
        noteHPChange(at: index, by: amount)
        appendLog(
            "\(combatants[index].name)'s max HP increased by \(amount) (\(combatants[index].currentHP!)/\(combatants[index].maxHP!) HP)",
            combatantId: id,
            hpOperation: .maxHPIncrease(amount: amount)
        )
    }

    /// Sets current HP directly, clamped to 0...max. A correction, so temporary HP
    /// does not absorb anything. Reaching 0 starts dying or death as damage would.
    func setCurrentHP(for id: UUID, to value: Int) {
        guard let index = combatants.firstIndex(where: { $0.id == id }),
              let maxHP = combatants[index].maxHP,
              let current = combatants[index].currentHP else { return }
        let newValue = Swift.min(Swift.max(0, value), maxHP)
        guard newValue != current else { return }
        combatants[index].currentHP = newValue
        noteHPChange(at: index, by: newValue - current)
        appendLog(
            "\(combatants[index].name)'s HP set to \(newValue)/\(maxHP)",
            combatantId: id,
            hpOperation: .setCurrentHP(value: newValue)
        )
        startDyingOrDieIfNeeded(at: index)
        clearDeathSavesIfAboveZero(at: index)
    }

    /// Sets max HP directly (at least 1; use "Lower max" to take it to 0). Current
    /// HP comes down with it if it is now above the max, and does not go up.
    func setMaxHP(for id: UUID, to value: Int) {
        guard let index = combatants.firstIndex(where: { $0.id == id }),
              let maxHP = combatants[index].maxHP,
              let current = combatants[index].currentHP else { return }
        let newMax = Swift.max(1, value)
        guard newMax != maxHP else { return }
        combatants[index].maxHP = newMax
        noteMaxHPChange(at: index, by: newMax - maxHP)
        combatants[index].currentHP = Swift.min(current, newMax)
        noteHPChange(at: index, by: combatants[index].currentHP! - current)
        appendLog(
            "\(combatants[index].name)'s max HP set to \(newMax) (\(combatants[index].currentHP!)/\(newMax) HP)",
            combatantId: id,
            hpOperation: .setMaxHP(value: newMax)
        )
    }

    /// Sets temporary HP directly; 0 clears it. Unlike a grant, this can lower it.
    func setTemporaryHP(for id: UUID, to value: Int) {
        guard let index = combatants.firstIndex(where: { $0.id == id }),
              combatants[index].currentHP != nil else { return }
        let newValue = Swift.max(0, value)
        guard newValue != (combatants[index].temporaryHP ?? 0) else { return }
        combatants[index].temporaryHP = newValue > 0 ? newValue : nil
        appendLog(
            newValue > 0
                ? "\(combatants[index].name)'s temporary HP set to \(newValue)"
                : "\(combatants[index].name)'s temporary HP cleared",
            combatantId: id,
            hpOperation: .setTemporaryHP(value: newValue)
        )
    }

    /// How far a heal would take current HP past max. Zero when it stays within max.
    static func healOverflow(current: Int, max: Int, amount: Int) -> Int {
        Swift.max(0, current + amount - max)
    }

    /// Heals a combatant. A heal past max either goes above max as temporary HP, which
    /// replaces any earlier temporary HP, or caps at max. Within max, both are the same.
    func heal(_ id: UUID, amount: Int, goAboveMax: Bool) {
        guard amount > 0, let index = combatants.firstIndex(where: { $0.id == id }),
              let current = combatants[index].currentHP,
              let maxHP = combatants[index].maxHP else { return }
        let overflow = Self.healOverflow(current: current, max: maxHP, amount: amount)
        guard goAboveMax, overflow > 0 else {
            applyHealing(to: id, amount: amount)
            return
        }
        combatants[index].currentHP = maxHP
        combatants[index].temporaryHP = overflow
        noteHPChange(at: index, by: maxHP - current)
        clearDeathSavesIfAboveZero(at: index)
        appendLog(
            "\(combatants[index].name) healed \(amount) HP and gained \(overflow) temporary HP (\(maxHP)/\(maxHP) HP)",
            combatantId: id,
            hpOperation: .healAboveMax(amount: amount)
        )
    }

    /// Lowers max HP by `amount`, and brings current HP down with it if it is now above the max.
    func decreaseMaxHP(for id: UUID, amount: Int) {
        guard amount > 0, let index = combatants.firstIndex(where: { $0.id == id }),
              let maxHP = combatants[index].maxHP,
              let current = combatants[index].currentHP else { return }
        let newMax = max(0, maxHP - amount)
        combatants[index].maxHP = newMax
        noteMaxHPChange(at: index, by: newMax - maxHP)
        combatants[index].currentHP = min(current, newMax)
        noteHPChange(at: index, by: combatants[index].currentHP! - current)
        appendLog(
            "\(combatants[index].name)'s max HP decreased by \(maxHP - newMax) (\(combatants[index].currentHP!)/\(newMax) HP)",
            combatantId: id,
            hpOperation: .maxHPDecrease(amount: amount)
        )
        // A max of 0 kills outright, with no death saves.
        if newMax == 0, combatants[index].isPlayer, combatants[index].deathSaves?.isDead != true {
            combatants[index].deathSaves = DeathSaves(successes: 0, failures: DeathSaves.required)
            appendLog("\(combatants[index].name) died (max HP reduced to 0)", combatantId: id)
        }
    }

    /// Changes armor class by `delta` (negative lowers it), for the rest of the
    /// encounter. Armor class never goes below zero.
    func adjustArmorClass(for id: UUID, by delta: Int) {
        guard delta != 0, let index = combatants.firstIndex(where: { $0.id == id }),
              let ac = combatants[index].armorClass else { return }
        let newAC = max(0, ac + delta)
        combatants[index].armorClass = newAC
        let total = (combatants[index].recentACChange ?? 0) + (newAC - ac)
        combatants[index].recentACChange = total == 0 ? nil : total
        appendLog("\(combatants[index].name)'s armor class \(newAC - ac >= 0 ? "rose" : "fell") to \(newAC)", combatantId: id)
    }

    /// Sets armor class directly (at least 0), as a correction.
    func setArmorClass(for id: UUID, to value: Int) {
        guard let index = combatants.firstIndex(where: { $0.id == id }),
              let ac = combatants[index].armorClass else { return }
        adjustArmorClass(for: id, by: Swift.max(0, value) - ac)
    }

    /// Sets temporary AC directly; 0 clears it. Unlike a grant, this can lower it.
    func setTemporaryAC(for id: UUID, to value: Int) {
        guard let index = combatants.firstIndex(where: { $0.id == id }),
              combatants[index].armorClass != nil else { return }
        let newValue = Swift.max(0, value)
        guard newValue != (combatants[index].temporaryAC ?? 0) else { return }
        combatants[index].temporaryAC = newValue > 0 ? newValue : nil
        appendLog(
            newValue > 0
                ? "\(combatants[index].name)'s temporary AC set to \(newValue)"
                : "\(combatants[index].name)'s temporary AC cleared",
            combatantId: id
        )
    }

    private func noteMaxHPChange(at index: Int, by delta: Int) {
        guard delta != 0 else { return }
        let total = (combatants[index].recentMaxHPChange ?? 0) + delta
        combatants[index].recentMaxHPChange = total == 0 ? nil : total
    }

    /// Adds a change to the combatant's running HP change for this turn cycle.
    private func noteHPChange(at index: Int, by delta: Int) {
        guard delta != 0 else { return }
        let total = (combatants[index].recentHPChange ?? 0) + delta
        combatants[index].recentHPChange = total == 0 ? nil : total
    }

    /// Deletes a log entry. If it carried an HP operation, the affected combatant's
    /// current/max HP is recomputed from scratch by replaying the remaining
    /// HP-operation entries for that combatant, in order — see `replayHP`.
    func deleteLogEntry(_ entryId: UUID) {
        guard let index = log.firstIndex(where: { $0.id == entryId }) else { return }
        let entry = log[index]
        log.remove(at: index)
        let replayedCombatant = entry.hpOperation != nil ? entry.combatantId : nil
        if let replayedCombatant {
            Self.replayHP(of: replayedCombatant, in: &combatants, from: log)
        }
        // Undo snapshots taken after the entry was logged held it too. Take it out
        // of each, or Previous would cut the log one entry too late and bring back
        // the HP the deletion took away.
        for i in history.indices where history[i].logCount > index {
            history[i].logCount -= 1
            if let replayedCombatant {
                Self.replayHP(of: replayedCombatant, in: &history[i].combatants, from: Array(log.prefix(history[i].logCount)))
            }
        }
    }

    /// Recomputes one combatant's HP from scratch by replaying `log`'s HP operations.
    private static func replayHP(of combatantId: UUID, in combatants: inout [Combatant], from log: [LogEntry]) {
        guard let index = combatants.firstIndex(where: { $0.id == combatantId }) else { return }
        var maxHP: Int?
        var currentHP: Int?
        var temporaryHP: Int?
        var maxHPIncreased = false
        for entry in log where entry.combatantId == combatantId {
            switch entry.hpOperation {
            case .enableTracking(let amount):
                maxHP = amount
                currentHP = amount
            case .grantTemporaryHP(let amount):
                temporaryHP = Self.grantedTemporaryHP(existing: temporaryHP, new: amount)
            case .damage(let amount):
                guard let current = currentHP else { continue }
                let result = Self.absorb(damage: amount, temporaryHP: temporaryHP, currentHP: current)
                temporaryHP = result.temporaryHP
                currentHP = result.currentHP
            case .healing(let amount):
                guard let current = currentHP, let max = maxHP else { continue }
                currentHP = min(max, current + amount)
            case .maxHPIncrease(let amount):
                guard let max = maxHP, let current = currentHP else { continue }
                maxHP = max + amount
                currentHP = current + amount
                maxHPIncreased = true
            case .maxHPDecrease(let amount):
                guard let ceiling = maxHP, let current = currentHP else { continue }
                let reduced = Swift.max(0, ceiling - amount)
                maxHP = reduced
                currentHP = Swift.min(current, reduced)
            case .setCurrentHP(let value):
                guard let ceiling = maxHP else { continue }
                currentHP = Swift.min(Swift.max(0, value), ceiling)
            case .setMaxHP(let value):
                guard let current = currentHP else { continue }
                maxHP = value
                currentHP = Swift.min(current, value)
            case .setTemporaryHP(let value):
                temporaryHP = value > 0 ? value : nil
            case .healAboveMax(let amount):
                guard let current = currentHP, let max = maxHP else { continue }
                let overflow = Self.healOverflow(current: current, max: max, amount: amount)
                currentHP = Swift.min(max, current + amount)
                if overflow > 0 { temporaryHP = overflow }
            case .kill:
                guard currentHP != nil else { continue }
                currentHP = 0
            case .revive:
                guard let current = currentHP else { continue }
                currentHP = Swift.max(1, current)
            case nil:
                continue
            }
        }
        combatants[index].maxHP = maxHP
        combatants[index].currentHP = currentHP
        combatants[index].temporaryHP = temporaryHP
        combatants[index].maxHPIncreased = maxHPIncreased
        // Deleting the log entry that dropped someone to 0 has to take the death
        // saves with it, or they'd be left rolling at full health.
        if let currentHP, currentHP > 0 {
            combatants[index].deathSaves = nil
        }
    }

    // MARK: - Effects
    //
    // Adding and removing effects lives here rather than in the views that do it
    // so that the behaviour is testable and so every path logs the same way —
    // the log is the session's history, and an effect appearing or going is as
    // much a part of what happened as a hit point change.

    func addEffect(_ effect: Effect, to combatantID: UUID) {
        guard let index = combatants.firstIndex(where: { $0.id == combatantID }) else { return }
        combatants[index].effects.append(effect)
        appendLog("\(combatants[index].name): \(effect.name)", combatantId: combatantID)
    }

    func removeEffect(_ effectID: UUID, from combatantID: UUID) {
        guard let index = combatants.firstIndex(where: { $0.id == combatantID }),
              let effect = combatants[index].effects.first(where: { $0.id == effectID }) else { return }
        combatants[index].effects.removeAll { $0.id == effectID }
        appendLog("\(combatants[index].name): \(effect.name) removed", combatantId: combatantID)
    }

    /// Replaces an effect in place, keeping its identity. Used by the editor, so
    /// reconfiguring a condition doesn't read as removing one and adding another.
    func updateEffect(_ effect: Effect, on combatantID: UUID) {
        guard let index = combatants.firstIndex(where: { $0.id == combatantID }),
              let effectIndex = combatants[index].effects.firstIndex(where: { $0.id == effect.id }) else { return }
        combatants[index].effects[effectIndex] = effect
    }

    /// The combatant's own effect with this name, if any. Case-insensitive,
    /// because an effect's name can be typed by hand as well as picked.
    func effect(named name: String, on combatantID: UUID) -> Effect? {
        combatants.first { $0.id == combatantID }?
            .visibleEffects.first { $0.name.localizedCaseInsensitiveCompare(name) == .orderedSame }
    }

    // MARK: - Round effects

    func addRoundEffect(_ effect: Effect) {
        roundEffects.append(effect)
        appendLog("Round effect: \(effect.name)")
    }

    func removeRoundEffect(_ effectID: UUID) {
        guard let effect = roundEffects.first(where: { $0.id == effectID }) else { return }
        roundEffects.removeAll { $0.id == effectID }
        appendLog("Round effect ended: \(effect.name)")
    }

    func updateRoundEffect(_ effect: Effect) {
        guard let index = roundEffects.firstIndex(where: { $0.id == effect.id }) else { return }
        roundEffects[index] = effect
    }

    /// True when the *next* advance rolls the round over. Round-anchored things
    /// key off this rather than off any combatant's turn.
    /// The next combatant who can act after `index`. Dead combatants are passed
    /// over: a creature at 0 HP, or a character whose death saves failed. `wrapped`
    /// is true when the walk passes the end of the list, which starts a new round.
    /// If nobody else can act, the result is `index` itself.
    /// The combatant the roster marks as current. While start-of-turn prompts are
    /// open, that is the one whose turn is about to start, so the marker shows who
    /// the prompt is for. Cancelling clears the prompts and the marker returns to
    /// the turn that is still in progress.
    func highlightedCombatantID(awaitingPrompts: Bool) -> UUID? {
        guard awaitingPrompts, combatants.indices.contains(currentTurnIndex) else {
            return currentCombatant?.id
        }
        let (nextIndex, _) = nextActiveIndex(after: currentTurnIndex)
        return combatants[nextIndex].id
    }

    func nextActiveIndex(after index: Int) -> (index: Int, wrapped: Bool) {
        var next = index
        var wrapped = false
        repeat {
            if next == combatants.count - 1 { wrapped = true }
            next = (next + 1) % combatants.count
        } while combatants[next].isDead && next != index
        return (next, wrapped)
    }

    private func tickRoundEffects() {
        roundEffects = roundEffects.compactMap { effect in
            guard case .forRounds(let remaining) = effect.durationType else { return effect }
            if remaining <= 1 {
                appendLog("Round effect ended: \(effect.name)")
                return nil
            }
            var updated = effect
            updated.durationType = .forRounds(remaining: remaining - 1)
            return updated
        }
    }

    // MARK: - Reaction

    private static let reactionEffectName = "Reaction Used"

    func useReaction(for id: UUID) {
        guard let index = combatants.firstIndex(where: { $0.id == id }), !combatants[index].reactionUsed else { return }
        combatants[index].effects.append(
            Effect(name: Self.reactionEffectName, durationType: .untilStartOfTheirTurn(remainingTurns: 1), isReactionMarker: true)
        )
    }

    func resetReaction(for id: UUID) {
        guard let index = combatants.firstIndex(where: { $0.id == id }) else { return }
        combatants[index].effects.removeAll { $0.isReactionMarker == true }
    }

    func toggleReaction(for id: UUID) {
        guard let index = combatants.firstIndex(where: { $0.id == id }) else { return }
        if combatants[index].reactionUsed {
            resetReaction(for: id)
        } else {
            useReaction(for: id)
        }
    }

    // MARK: - Limited uses

    /// Legendary Actions and the like: a countable resource, not an on/off. The
    /// modal that creates one asks for a count up front because there's no
    /// sensible default to guess the way a condition's usual duration can be.
    func addLimitedUse(name: String, total: Int, to id: UUID) {
        guard let index = combatants.firstIndex(where: { $0.id == id }) else { return }
        let use = LimitedUse(name: name, total: total)
        combatants[index].limitedUses.append(use)
        appendLog("\(combatants[index].name): \(use.name) (\(use.total) uses)", combatantId: id)
    }

    /// Renaming or changing the count via the cog — clamps `remaining` to the
    /// new `total` so shrinking the count can't leave more remaining than exist.
    func updateLimitedUse(_ use: LimitedUse, on id: UUID) {
        guard let index = combatants.firstIndex(where: { $0.id == id }),
              let useIndex = combatants[index].limitedUses.firstIndex(where: { $0.id == use.id }) else { return }
        var clamped = use
        clamped.remaining = min(clamped.remaining, clamped.total)
        combatants[index].limitedUses[useIndex] = clamped
    }

    func removeLimitedUse(_ useID: UUID, from id: UUID) {
        guard let index = combatants.firstIndex(where: { $0.id == id }) else { return }
        combatants[index].limitedUses.removeAll { $0.id == useID }
    }

    /// Spends one use, same tap-to-activate motion as `toggleReaction` but
    /// counting down instead of flipping a bool. Does nothing once exhausted —
    /// the cog is how a DM corrects a mistaken tap, not another tap here.
    func useLimitedUse(_ useID: UUID, on id: UUID) {
        guard let index = combatants.firstIndex(where: { $0.id == id }),
              let useIndex = combatants[index].limitedUses.firstIndex(where: { $0.id == useID }),
              combatants[index].limitedUses[useIndex].remaining > 0 else { return }
        combatants[index].limitedUses[useIndex].remaining -= 1
        let use = combatants[index].limitedUses[useIndex]
        appendLog("\(combatants[index].name) used \(use.name) (\(use.remaining)/\(use.total) left)", combatantId: id)
    }

    /// Refills every limited use on every combatant when the round turns over —
    /// unlike `Reaction`, these aren't tied to one combatant's own turn: a
    /// Legendary Action budget (and anything else tracked this way) reads more
    /// naturally as "you get this many per round" than "this many by the time
    /// your turn comes back around".
    private func resetLimitedUses() {
        for index in combatants.indices {
            for useIndex in combatants[index].limitedUses.indices {
                combatants[index].limitedUses[useIndex].remaining = combatants[index].limitedUses[useIndex].total
            }
        }
    }

    /// Saves the current state so Previous can rewind to it. Used by actions that
    /// change the fight without advancing the turn.
    private func recordUndoPoint() {
        history.append((combatants: combatants, roundEffects: roundEffects, currentTurnIndex: currentTurnIndex, roundNumber: roundNumber, logCount: log.count))
    }

    func removeCombatant(id: UUID) {
        guard let index = combatants.firstIndex(where: { $0.id == id }) else { return }
        recordUndoPoint()
        let name = combatants[index].name
        combatants.remove(at: index)
        if index < currentTurnIndex || (index == currentTurnIndex && currentTurnIndex == combatants.count) {
            currentTurnIndex = max(0, currentTurnIndex - 1)
        }
        appendLog("\(name) removed from combat")
    }

    /// Kills a combatant: a tracked HP goes to 0 and death saves end; a combatant with
    /// no HP is marked dead. Undoable with Previous.
    func kill(_ id: UUID) {
        guard let index = combatants.firstIndex(where: { $0.id == id }), !combatants[index].isDead else { return }
        recordUndoPoint()
        let tracked = combatants[index].currentHP != nil
        if tracked {
            combatants[index].currentHP = 0
            combatants[index].deathSaves = nil
        } else {
            combatants[index].markedDead = true
        }
        appendLog("\(combatants[index].name) was killed", combatantId: id, hpOperation: tracked ? .kill : nil)
        if combatants[index].isConcentrating {
            combatants[index].isConcentrating = false
            appendLog("\(combatants[index].name) lost concentration", combatantId: id)
        }
    }

    /// Brings a dead combatant back. A tracked HP at 0 comes back to 1. Undoable with Previous.
    func revive(_ id: UUID) {
        guard let index = combatants.firstIndex(where: { $0.id == id }), combatants[index].isDead else { return }
        recordUndoPoint()
        let tracked = combatants[index].currentHP != nil
        if tracked {
            combatants[index].currentHP = max(1, combatants[index].currentHP ?? 1)
            combatants[index].deathSaves = nil
        }
        combatants[index].markedDead = nil
        appendLog("\(combatants[index].name) was revived", combatantId: id, hpOperation: tracked ? .revive : nil)
    }

    // MARK: - Turn order

    /// Everything the DM has to answer before this turn can end: rolls owed by
    /// the combatant whose turn is finishing, then rolls and death saves owed by
    /// the one whose turn is about to start.
    ///
    /// Both belong to the same tap on Next even though they belong to different
    /// combatants, and showing them together is deliberate — it's one interruption
    /// at the boundary rather than two either side of it.
    func pendingTurnPrompts() -> [TurnPrompt] {
        guard combatants.count > 0, combatants.indices.contains(currentTurnIndex) else { return [] }

        let ending = combatants[currentTurnIndex]
        let (nextIndex, wrapsRound) = nextActiveIndex(after: currentTurnIndex)
        let starting = combatants[nextIndex]

        var prompts = rollPrompts(for: ending, at: .endOfTurn)
        prompts += rollPrompts(for: starting, at: .startOfTurn)
        prompts += damagePrompts(for: starting)

        // Round-anchored rolls come due when the round turns over, not on
        // anyone's turn — so they ride on the advance that wraps.
        if wrapsRound {
            prompts += roundEffects.compactMap { effect in
                guard effect.durationType.awaitsRoll else { return nil }
                guard case .untilRollSucceeds(_, let hint) = effect.durationType else { return nil }
                return TurnPrompt(
                    id: effect.id,
                    combatantID: nil,
                    combatantName: "The round",
                    subject: .roundEffect(id: effect.id),
                    title: "Roll for \(effect.name)",
                    hint: hint,
                    deathSaves: nil
                )
            }
        }
        if let saves = starting.deathSaves, !saves.isResolved {
            prompts.append(
                TurnPrompt(
                    id: starting.id,
                    combatantID: starting.id,
                    combatantName: starting.name,
                    subject: .deathSave,
                    title: "Death save",
                    hint: nil,
                    deathSaves: saves
                )
            )
        }
        return prompts
    }

    /// "Roll to recharge Breath Weapon". A recharge already named "Recharging"
    /// (the default name) would read "Roll to recharge Recharging", so it is
    /// phrased as "Roll: Recharging" instead.
    static func rechargeTitle(for name: String) -> String {
        name.lowercased().hasPrefix("recharg") ? "Roll: \(name)" : "Roll to recharge \(name)"
    }

    /// Effects that hurt at the start of their owner's turn, and what to roll for them.
    /// The app asks and applies; the DM rolls.
    private static let startOfTurnDamage: [String: String] = ["Burning": "1d4 fire"]

    private func damagePrompts(for combatant: Combatant) -> [TurnPrompt] {
        combatant.effects.compactMap { effect in
            // Case-insensitive, like every other effect-name match: the name can be typed.
            guard let hint = Self.startOfTurnDamage.first(where: { $0.key.localizedCaseInsensitiveCompare(effect.name) == .orderedSame })?.value,
                  combatant.currentHP != nil else { return nil }
            return TurnPrompt(
                id: effect.id,
                combatantID: combatant.id,
                combatantName: combatant.name,
                subject: .damage(effectID: effect.id),
                title: "\(effect.name): damage this turn",
                hint: hint,
                deathSaves: nil
            )
        }
    }

    private func rollPrompts(for combatant: Combatant, at boundary: TurnBoundary) -> [TurnPrompt] {
        combatant.effects.compactMap { effect in
            guard case .untilRollSucceeds(let effectBoundary, let hint) = effect.durationType,
                  effectBoundary == boundary else { return nil }
            return TurnPrompt(
                id: effect.id,
                combatantID: combatant.id,
                combatantName: combatant.name,
                subject: .effect(id: effect.id),
                title: effect.kind == .cooldown ? Self.rechargeTitle(for: effect.name) : "Roll a save vs \(effect.name)",
                hint: hint,
                deathSaves: nil
            )
        }
    }

    /// Applies one prompt's outcome. Success removes the effect; for a death save
    /// both outcomes count toward their own total; for a concentration check the
    /// sense is inverted and *failing* removes it. The DM decides — nothing here
    /// rolls anything.
    ///
    /// Public because concentration checks arrive from damage rather than from a
    /// turn boundary, so the detail screen resolves them directly instead of
    /// handing them to `nextTurn`.
    func resolvePrompt(_ prompt: TurnPrompt, succeeded: Bool) {
        resolvePrompt(prompt, outcome: RollOutcome(succeeded: succeeded))
    }

    func resolvePrompt(_ prompt: TurnPrompt, outcome: RollOutcome) {
        let succeeded = outcome.succeeded
        if case .roundEffect(let effectID) = prompt.subject {
            guard let effect = roundEffects.first(where: { $0.id == effectID }) else { return }
            if succeeded {
                roundEffects.removeAll { $0.id == effectID }
                appendLog("Round effect ended: \(effect.name)")
            } else {
                appendLog("Round effect continues: \(effect.name)")
            }
            return
        }

        guard let combatantID = prompt.combatantID,
              let index = combatants.firstIndex(where: { $0.id == combatantID }) else { return }

        switch prompt.subject {
        case .effect(let effectID):
            guard let effect = combatants[index].effects.first(where: { $0.id == effectID }) else { return }
            if succeeded {
                combatants[index].effects.removeAll { $0.id == effectID }
                appendLog(
                    effect.kind == .cooldown
                        ? "\(combatants[index].name) recharged \(effect.name)"
                        : "\(combatants[index].name) shook off \(effect.name)",
                    combatantId: combatants[index].id
                )
            } else {
                appendLog("\(combatants[index].name) failed the roll for \(effect.name)", combatantId: combatants[index].id)
            }

        case .concentration:
            if succeeded {
                appendLog("\(combatants[index].name) held concentration", combatantId: combatants[index].id)
            } else {
                combatants[index].isConcentrating = false
                appendLog("\(combatants[index].name) lost concentration", combatantId: combatants[index].id)
            }

        case .roundEffect:
            return // handled above, before the combatant lookup

        case .damage:
            return // the amount comes with the answer; `nextTurn` applies it

        case .deathSave:
            guard combatants[index].deathSaves != nil else { return }
            if outcome == .criticalSuccess {
                // A natural 20 regains 1 HP, which ends the dying state.
                combatants[index].deathSaves = nil
                combatants[index].currentHP = 1
                appendLog("\(combatants[index].name) rolled a natural 20 and regained 1 HP", combatantId: combatants[index].id, hpOperation: .revive)
                return
            }
            if outcome == .criticalFailure {
                combatants[index].deathSaves?.recordCriticalFailure()
            } else {
                combatants[index].deathSaves?.record(success: succeeded)
            }
            guard let saves = combatants[index].deathSaves else { return }
            let roll = outcome == .criticalFailure ? "a natural 1 (two failures)" : "a death save"
            appendLog(
                "\(combatants[index].name) \(succeeded ? "made" : "failed") \(roll) (\(saves.successes) made, \(saves.failures) failed)",
                combatantId: combatants[index].id
            )
            if saves.isStable {
                appendLog("\(combatants[index].name) stabilised", combatantId: combatants[index].id)
            } else if saves.isDead {
                appendLog("\(combatants[index].name) died", combatantId: combatants[index].id)
            }
        }
    }

    /// Advances the turn, first applying any prompt answers the DM gave.
    ///
    /// The answers are applied **after** the history snapshot and before the
    /// advance, deliberately: that puts them inside the same undo step, so
    /// Previous rewinds the save you just recorded along with the turn it
    /// belonged to, rather than leaving it stranded.
    ///
    /// `damage` carries the amounts typed for damage prompts (Burning). They are applied
    /// once the new turn has begun, so the change shows beside the HP of the combatant
    /// whose turn it now is. Returns any prompt that damage raised (a concentration
    /// check), for the caller to ask.
    @discardableResult
    func nextTurn(resolving answers: [TurnPrompt: RollOutcome] = [:], damage: [TurnPrompt: Int] = [:]) -> [TurnPrompt] {
        guard !combatants.isEmpty else { return [] }

        history.append((combatants: combatants, roundEffects: roundEffects, currentTurnIndex: currentTurnIndex, roundNumber: roundNumber, logCount: log.count))

        for (prompt, outcome) in answers.sorted(by: { $0.key.combatantName < $1.key.combatantName }) {
            resolvePrompt(prompt, outcome: outcome)
        }

        let endingCombatantId = combatants[currentTurnIndex].id
        let (nextIndex, wrapped) = nextActiveIndex(after: currentTurnIndex)
        currentTurnIndex = nextIndex
        if wrapped {
            roundNumber += 1
            appendLog("Round \(roundNumber) began")
            tickRoundEffects()
            resetLimitedUses()
        }
        let startingCombatantId = combatants[currentTurnIndex].id
        combatants[currentTurnIndex].recentHPChange = nil
        combatants[currentTurnIndex].recentMaxHPChange = nil
        combatants[currentTurnIndex].recentACChange = nil

        removeExpiredEffects(
            turnEndingCombatantId: endingCombatantId,
            turnStartingCombatantId: startingCombatantId
        )

        appendLog("\(combatants[currentTurnIndex].name)'s turn")

        var followUps: [TurnPrompt] = []
        for (prompt, amount) in damage.sorted(by: { $0.key.combatantName < $1.key.combatantName }) {
            guard let combatantID = prompt.combatantID, amount > 0,
                  let followUp = applyDamage(to: combatantID, amount: amount) else { continue }
            followUps.append(followUp)
        }
        return followUps
    }

    /// Reverts combatants/turn index/round number to the pre-nextTurn() snapshot,
    /// and truncates the log back to its length at that same point — anything
    /// logged during the turn being undone (damage, heals, etc.) is removed too,
    /// so the log never shows events for a turn that's no longer considered to
    /// have happened.
    func previousTurn() {
        guard let previous = history.popLast() else { return }
        combatants = previous.combatants
        roundEffects = previous.roundEffects
        currentTurnIndex = previous.currentTurnIndex
        roundNumber = previous.roundNumber
        log = Array(log.prefix(previous.logCount))
    }

    /// Clears all combat state and assigns a fresh identity, for starting a brand-new session.
    func reset() {
        id = UUID()
        name = CombatSession.defaultName()
        combatants = []
        roundEffects = []
        currentTurnIndex = 0
        roundNumber = 1
        log = []
        history = []
    }

    // MARK: - Persistence

    func makeRecord() -> SessionRecord {
        SessionRecord(id: id, name: name, combatants: combatants, currentTurnIndex: currentTurnIndex, roundNumber: roundNumber, log: log, roundEffects: roundEffects)
    }

    func load(_ record: SessionRecord) {
        id = record.id
        name = record.name
        combatants = record.combatants
        roundEffects = record.roundEffects ?? []
        currentTurnIndex = record.currentTurnIndex
        roundNumber = record.roundNumber ?? 1
        log = record.log ?? []
        history = []
    }

    private func removeExpiredEffects(turnEndingCombatantId: UUID, turnStartingCombatantId: UUID) {
        for i in combatants.indices {
            let ownerId = combatants[i].id
            combatants[i].effects = combatants[i].effects.compactMap { effect in
                switch effect.durationType {
                case .untilEndOfTheirTurn(let remaining):
                    guard ownerId == turnEndingCombatantId else { return effect }
                    return Self.tick(effect, remaining: remaining, makeDuration: DurationType.untilEndOfTheirTurn)
                case .untilStartOfTheirTurn(let remaining):
                    guard ownerId == turnStartingCombatantId else { return effect }
                    return Self.tick(effect, remaining: remaining, makeDuration: DurationType.untilStartOfTheirTurn)
                case .untilRollSucceeds:
                    // Never ages out. It leaves when the DM says the roll
                    // succeeded — see pendingTurnPrompts.
                    return effect
                case .untilRemoved:
                    // Countered by doing something about it, on no schedule.
                    return effect
                case .forRounds:
                    // Only meaningful on a round-anchored effect, which doesn't
                    // live on a combatant — see tickRoundEffects().
                    return effect
                }
            }
        }
    }

    /// Counts one turn boundary off a duration's `remainingTurns`. Returns nil (drop
    /// the effect) once the count reaches zero, otherwise the same effect with the
    /// count decremented.
    private static func tick(_ effect: Effect, remaining: Int, makeDuration: (Int) -> DurationType) -> Effect? {
        if remaining <= 1 { return nil }
        var updated = effect
        updated.durationType = makeDuration(remaining - 1)
        return updated
    }
}
