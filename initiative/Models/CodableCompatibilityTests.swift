import XCTest
@testable import initiative

/// Saved sessions are JSON on disk that outlives any single build of the app, so
/// the encodings below are a compatibility surface, not an implementation detail:
/// a decoder that stops understanding an older payload silently wipes somebody's
/// in-progress combat. These tests decode literal JSON — deliberately not
/// round-tripped through the current encoder — so they still fail if a future
/// change breaks yesterday's files while remaining self-consistent.
///
/// See CLAUDE.md, "Session persistence compatibility".
final class CodableCompatibilityTests: XCTestCase {

    private func decode<T: Decodable>(_ type: T.Type, _ json: String) throws -> T {
        try JSONDecoder().decode(type, from: Data(json.utf8))
    }

    // MARK: - DurationType

    func testDecodesCurrentDurationKinds() throws {
        let start = try decode(DurationType.self, #"{"kind":"untilStartOfTheirTurn","remainingTurns":3}"#)
        XCTAssertEqual(start, .untilStartOfTheirTurn(remainingTurns: 3))

        let end = try decode(DurationType.self, #"{"kind":"untilEndOfTheirTurn","remainingTurns":2}"#)
        XCTAssertEqual(end, .untilEndOfTheirTurn(remainingTurns: 2))
    }

    /// Target-anchored durations were removed when the model was simplified to
    /// owner-only turns. Sessions saved before that still name those kinds, and
    /// they must collapse into the owner-turn equivalent rather than throw —
    /// throwing would fail the whole `SessionRecord` decode and lose the session.
    func testDecodesRetiredTargetDurationsAsOwnerTurns() throws {
        let start = try decode(DurationType.self, #"{"kind":"untilStartOfTargetTurn","remainingTurns":4}"#)
        XCTAssertEqual(start, .untilStartOfTheirTurn(remainingTurns: 4))

        let end = try decode(DurationType.self, #"{"kind":"untilEndOfTargetTurn","remainingTurns":1}"#)
        XCTAssertEqual(end, .untilEndOfTheirTurn(remainingTurns: 1))
    }

    /// `remainingTurns` postdates the original encoding; a payload without it is
    /// a single-turn effect, not a zero-turn one (which would expire instantly).
    func testMissingRemainingTurnsDefaultsToOne() throws {
        let duration = try decode(DurationType.self, #"{"kind":"untilEndOfTheirTurn"}"#)
        XCTAssertEqual(duration, .untilEndOfTheirTurn(remainingTurns: 1))
    }

    func testUnknownDurationKindFailsLoudly() {
        // Not something to paper over: an unrecognised kind means the file was
        // written by a *newer* build, and guessing at its meaning would silently
        // corrupt the effect rather than surface the problem.
        XCTAssertThrowsError(try decode(DurationType.self, #"{"kind":"untilTheDragonRecharges"}"#))
    }

    func testDurationTypeRoundTrips() throws {
        for duration: DurationType in [
            .untilStartOfTheirTurn(remainingTurns: 1),
            .untilStartOfTheirTurn(remainingTurns: 9),
            .untilEndOfTheirTurn(remainingTurns: 1),
            .untilEndOfTheirTurn(remainingTurns: 20),
        ] {
            let data = try JSONEncoder().encode(duration)
            XCTAssertEqual(try JSONDecoder().decode(DurationType.self, from: data), duration)
        }
    }

    // MARK: - Effect

    /// `isReactionMarker` postdates effects; without it being optional, every
    /// pre-existing effect in every saved session would fail to decode.
    func testEffectWithoutReactionMarkerDecodes() throws {
        let json = """
        {"id":"11111111-1111-1111-1111-111111111111","name":"Stunned",
         "durationType":{"kind":"untilEndOfTheirTurn","remainingTurns":1}}
        """
        let effect = try decode(Effect.self, json)
        XCTAssertEqual(effect.name, "Stunned")
        XCTAssertNil(effect.isReactionMarker)
    }

    /// A nil marker must behave as "not a marker" everywhere it's read, or old
    /// effects would start showing up as phantom used-reactions.
    func testNilReactionMarkerCountsAsNotAMarker() {
        var combatant = Combatant(name: "Goblin", initiative: 10)
        combatant.effects = [Effect(name: "Stunned", durationType: .untilEndOfTheirTurn(remainingTurns: 1))]
        XCTAssertFalse(combatant.reactionUsed)
        XCTAssertEqual(combatant.visibleEffects.count, 1)
    }

    // MARK: - HPOperation

    func testHPOperationRoundTrips() throws {
        for operation: HPOperation in [
            .enableTracking(amount: 30),
            .damage(amount: 7),
            .healing(amount: 4),
            .maxHPIncrease(amount: 10),
        ] {
            let data = try JSONEncoder().encode(operation)
            XCTAssertEqual(try JSONDecoder().decode(HPOperation.self, from: data), operation)
        }
    }

    // MARK: - SessionRecord

    /// The oldest shape on disk: no round number, no log. Both are optional and
    /// `CombatSession.load` supplies the defaults.
    func testDecodesSessionRecordWithoutRoundOrLog() throws {
        let json = """
        {"id":"22222222-2222-2222-2222-222222222222","name":"Old Save",
         "savedAt":0,"combatants":[],"currentTurnIndex":0}
        """
        let record = try decode(SessionRecord.self, json)
        XCTAssertNil(record.roundNumber)
        XCTAssertNil(record.log)

        let session = CombatSession()
        session.load(record)
        XCTAssertEqual(session.roundNumber, 1, "A record predating round tracking should resume at round 1")
        XCTAssertTrue(session.log.isEmpty)
    }

    /// A combatant saved before HP/AC tracking existed carries neither, and must
    /// still load as an untracked combatant rather than failing the whole record.
    func testDecodesCombatantWithoutHPOrArmorClass() throws {
        let json = """
        {"id":"33333333-3333-3333-3333-333333333333","name":"Bandit",
         "initiative":12,"effects":[]}
        """
        let combatant = try decode(Combatant.self, json)
        XCTAssertNil(combatant.maxHP)
        XCTAssertNil(combatant.currentHP)
        XCTAssertNil(combatant.armorClass)
        XCTAssertFalse(combatant.isDead, "No HP tracking means unknown, not dead")
    }

    /// A log entry from before structured HP operations existed decodes with a
    /// nil operation, which also makes it non-deletable — there's nothing to
    /// replay, so offering an undo for it would be a lie.
    func testDecodesLogEntryWithoutHPOperation() throws {
        let json = """
        {"id":"44444444-4444-4444-4444-444444444444","text":"Goblin's turn",
         "timestamp":0,"roundNumber":2}
        """
        let entry = try decode(LogEntry.self, json)
        XCTAssertNil(entry.hpOperation)
        XCTAssertFalse(entry.isDeletable)
    }

    /// End to end: a whole session written by an older build still restores.
    func testFullLegacyRecordLoadsIntoASession() throws {
        let json = """
        {"id":"55555555-5555-5555-5555-555555555555","name":"Legacy Fight",
         "savedAt":0,"currentTurnIndex":1,
         "combatants":[
           {"id":"66666666-6666-6666-6666-666666666666","name":"Hero","initiative":18,"effects":[]},
           {"id":"77777777-7777-7777-7777-777777777777","name":"Ogre","initiative":9,
            "effects":[{"id":"88888888-8888-8888-8888-888888888888","name":"Frightened",
                        "durationType":{"kind":"untilEndOfTargetTurn"}}]}
         ]}
        """
        let record = try decode(SessionRecord.self, json)
        let session = CombatSession()
        session.load(record)

        XCTAssertEqual(session.name, "Legacy Fight")
        XCTAssertEqual(session.combatants.count, 2)
        XCTAssertEqual(session.currentTurnIndex, 1)
        XCTAssertEqual(session.roundNumber, 1)
        XCTAssertEqual(
            session.combatants[1].effects.first?.durationType,
            .untilEndOfTheirTurn(remainingTurns: 1)
        )
    }
}

// MARK: - Fields added after the format shipped

extension CodableCompatibilityTests {

    /// Combatants saved before the player/NPC distinction existed must decode as
    /// NPCs — that's the reading under which they behave exactly as they did.
    func testCombatantWithoutIsPlayerDecodesAsNPC() throws {
        let json = """
        {"id":"\(UUID().uuidString)","name":"Goblin","initiative":12,"effects":[]}
        """.data(using: .utf8)!

        let combatant = try JSONDecoder().decode(Combatant.self, from: json)

        XCTAssertFalse(combatant.isPlayer)
        XCTAssertNil(combatant.deathSaves)
        XCTAssertFalse(combatant.isDying)
    }

    /// A missing `effects` key used to be a decode failure waiting to happen:
    /// Swift's synthesized decoder ignores declared defaults.
    func testCombatantWithoutEffectsDecodes() throws {
        let json = """
        {"id":"\(UUID().uuidString)","name":"Goblin","initiative":12}
        """.data(using: .utf8)!

        XCTAssertEqual(try JSONDecoder().decode(Combatant.self, from: json).effects.count, 0)
    }

    func testEffectWithoutKindDecodesAsCondition() throws {
        let json = """
        {"id":"\(UUID().uuidString)","name":"Stunned",
         "durationType":{"kind":"untilEndOfTheirTurn","remainingTurns":2}}
        """.data(using: .utf8)!

        XCTAssertEqual(try JSONDecoder().decode(Effect.self, from: json).kind, .condition)
    }

    func testRollRequiredDurationRoundTrips() throws {
        let original = Effect(
            name: "Breath Weapon",
            durationType: .untilRollSucceeds(at: .startOfTurn, hint: "5–6 on a d6"),
            kind: .cooldown
        )

        let decoded = try JSONDecoder().decode(Effect.self, from: JSONEncoder().encode(original))

        XCTAssertEqual(decoded.durationType, .untilRollSucceeds(at: .startOfTurn, hint: "5–6 on a d6"))
        XCTAssertEqual(decoded.kind, .cooldown)
    }

    /// A boundary written by some future version that this one doesn't recognise
    /// shouldn't lose the effect entirely.
    func testRollRequiredDurationWithoutABoundaryDefaultsToStartOfTurn() throws {
        let json = """
        {"kind":"untilRollSucceeds"}
        """.data(using: .utf8)!

        XCTAssertEqual(
            try JSONDecoder().decode(DurationType.self, from: json),
            .untilRollSucceeds(at: .startOfTurn, hint: nil)
        )
    }

    func testPresetWithoutIsPlayerDecodesAsNPC() throws {
        let json = """
        {"id":"\(UUID().uuidString)","name":"Goblin","maxHP":7}
        """.data(using: .utf8)!

        XCTAssertFalse(try JSONDecoder().decode(CreaturePreset.self, from: json).isPlayer)
    }
}

extension CodableCompatibilityTests {

    func testCombatantWithoutTemporaryHPDecodes() throws {
        let json = """
        {"id":"\(UUID().uuidString)","name":"Wren","initiative":12,"maxHP":30,"currentHP":30}
        """.data(using: .utf8)!

        XCTAssertNil(try JSONDecoder().decode(Combatant.self, from: json).temporaryHP)
    }

    func testGrantTemporaryHPOperationRoundTrips() throws {
        let original = HPOperation.grantTemporaryHP(amount: 8)
        let decoded = try JSONDecoder().decode(HPOperation.self, from: JSONEncoder().encode(original))
        XCTAssertEqual(decoded, original)
    }

    func testCombatantWithoutIsConcentratingDecodesAsFalse() throws {
        let json = """
        {"id":"\(UUID().uuidString)","name":"Wren","initiative":12}
        """.data(using: .utf8)!

        XCTAssertFalse(try JSONDecoder().decode(Combatant.self, from: json).isConcentrating)
    }

    func testIsConcentratingRoundTrips() throws {
        var combatant = Combatant(id: UUID(), name: "Wren", initiative: 12)
        combatant.isConcentrating = true

        let decoded = try JSONDecoder().decode(Combatant.self, from: JSONEncoder().encode(combatant))

        XCTAssertTrue(decoded.isConcentrating)
    }

    func testCombatantWithoutLimitedUsesDecodesEmpty() throws {
        let json = """
        {"id":"\(UUID().uuidString)","name":"Wren","initiative":12}
        """.data(using: .utf8)!

        XCTAssertTrue(try JSONDecoder().decode(Combatant.self, from: json).limitedUses.isEmpty)
    }

    func testLimitedUsesRoundTrip() throws {
        var combatant = Combatant(id: UUID(), name: "Ancient Dragon", initiative: 20)
        combatant.limitedUses = [LimitedUse(name: "Legendary Actions", total: 3, remaining: 1)]

        let decoded = try JSONDecoder().decode(Combatant.self, from: JSONEncoder().encode(combatant))

        XCTAssertEqual(decoded.limitedUses, combatant.limitedUses)
    }

    func testCombatantWithoutMaxHPIncreasedDecodesAsFalse() throws {
        let json = """
        {"id":"\(UUID().uuidString)","name":"Wren","initiative":12}
        """.data(using: .utf8)!

        XCTAssertFalse(try JSONDecoder().decode(Combatant.self, from: json).maxHPIncreased)
    }

    func testMaxHPIncreasedRoundTrips() throws {
        var combatant = Combatant(id: UUID(), name: "Wren", initiative: 12)
        combatant.maxHPIncreased = true

        let decoded = try JSONDecoder().decode(Combatant.self, from: JSONEncoder().encode(combatant))

        XCTAssertTrue(decoded.maxHPIncreased)
    }
}
