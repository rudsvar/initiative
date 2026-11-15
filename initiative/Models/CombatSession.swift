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

    var sortedCombatants: [Combatant] {
        combatants.sorted { $0.initiative > $1.initiative }
    }

    /// `initiative: nil` rolls 1...20 plus `initiativeBonus` (a flat modifier, e.g. from
    /// a creature preset). An explicit `initiative` value is used exactly as given —
    /// the bonus only applies to random rolls, never on top of a deliberate value.
    func addCombatant(name: String, initiative: Int? = nil, maxHP: Int? = nil, armorClass: Int? = nil, initiativeBonus: Int = 0, isPlayer: Bool = false) {
        let resolvedInitiative = initiative ?? (Int.random(in: 1...20) + initiativeBonus)
        let combatant = Combatant(name: name, initiative: resolvedInitiative, maxHP: maxHP, armorClass: armorClass, isPlayer: isPlayer)
        combatants.append(combatant)
        combatants.sort { $0.initiative > $1.initiative }
        appendLog("\(name) added to combat (initiative \(resolvedInitiative))")
        if let maxHP {
            // A separate, structured entry so recomputeHP has a baseline to replay
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
        combatants.sort { $0.initiative > $1.initiative }
        appendLog(count > 1 ? "\(count)x \(name) added to combat" : "\(name) added to combat")
        if let maxHP {
            // Same reasoning as addCombatant: a structured baseline entry per
            // spawned copy, tied to that copy's own id, so recomputeHP works.
            for combatant in spawned {
                appendLog(
                    "\(combatant.name) started tracking HP (\(maxHP)/\(maxHP))",
                    combatantId: combatant.id,
                    hpOperation: .enableTracking(amount: maxHP)
                )
            }
        }
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

        let absorbed = before - (result.temporaryHP ?? 0)
        let note = absorbed > 0 ? ", \(absorbed) absorbed" : ""
        appendLog(
            "\(combatants[index].name) took \(amount) damage\(note) (\(result.currentHP)/\(combatants[index].maxHP!) HP)",
            combatantId: id,
            hpOperation: .damage(amount: amount)
        )
        startDyingOrDieIfNeeded(at: index)
        return concentrationCheck(at: index, afterTaking: amount)
    }

    /// Splits an incoming hit between the temporary buffer and real hit points.
    ///
    /// Shared by `applyDamage` and `recomputeHP` deliberately: the live path and
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

    /// Grants temporary hit points, **replacing** whatever was there rather than
    /// adding to it. Two sources of temporary HP don't stack in any system this
    /// app is likely to be used with, and "replace" is the version a DM can
    /// predict without the app having a rule about which is larger.
    func grantTemporaryHP(to id: UUID, amount: Int) {
        guard amount > 0, let index = combatants.firstIndex(where: { $0.id == id }) else { return }
        combatants[index].temporaryHP = amount
        appendLog(
            "\(combatants[index].name) gained \(amount) temporary HP",
            combatantId: id,
            hpOperation: .grantTemporaryHP(amount: amount)
        )
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
            // The damage, not a DC: the threshold is a rule, and rules are the
            // DM's. What the app knows is how hard they were hit.
            hint: "Took \(amount) damage",
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
        combatants[index].currentHP = current + amount
        combatants[index].maxHPIncreased = true
        appendLog(
            "\(combatants[index].name)'s max HP increased by \(amount) (\(combatants[index].currentHP!)/\(combatants[index].maxHP!) HP)",
            combatantId: id,
            hpOperation: .maxHPIncrease(amount: amount)
        )
    }

    /// Deletes a log entry. If it carried an HP operation, the affected combatant's
    /// current/max HP is recomputed from scratch by replaying the remaining
    /// HP-operation entries for that combatant, in order — see `recomputeHP`.
    func deleteLogEntry(_ entryId: UUID) {
        guard let index = log.firstIndex(where: { $0.id == entryId }) else { return }
        let entry = log[index]
        log.remove(at: index)
        if let combatantId = entry.combatantId, entry.hpOperation != nil {
            recomputeHP(for: combatantId)
        }
    }

    private func recomputeHP(for combatantId: UUID) {
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
                temporaryHP = amount
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

    func removeCombatant(id: UUID) {
        guard let index = combatants.firstIndex(where: { $0.id == id }) else { return }
        let name = combatants[index].name
        combatants.remove(at: index)
        if index < currentTurnIndex || (index == currentTurnIndex && currentTurnIndex == combatants.count) {
            currentTurnIndex = max(0, currentTurnIndex - 1)
        }
        history.removeAll()
        appendLog("\(name) removed from combat")
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

        case .deathSave:
            guard combatants[index].deathSaves != nil else { return }
            combatants[index].deathSaves?.record(success: succeeded)
            guard let saves = combatants[index].deathSaves else { return }
            appendLog(
                "\(combatants[index].name) \(succeeded ? "made" : "failed") a death save (\(saves.successes) made, \(saves.failures) failed)",
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
    func nextTurn(resolving answers: [TurnPrompt: Bool] = [:]) {
        guard !combatants.isEmpty else { return }

        history.append((combatants: combatants, roundEffects: roundEffects, currentTurnIndex: currentTurnIndex, roundNumber: roundNumber, logCount: log.count))

        for (prompt, succeeded) in answers.sorted(by: { $0.key.combatantName < $1.key.combatantName }) {
            resolvePrompt(prompt, succeeded: succeeded)
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

        removeExpiredEffects(
            turnEndingCombatantId: endingCombatantId,
            turnStartingCombatantId: startingCombatantId
        )

        appendLog("\(combatants[currentTurnIndex].name)'s turn")
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
