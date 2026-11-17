import XCTest
@testable import initiative

final class PresetStoreTests: XCTestCase {
    var store: PresetStore!
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        store = PresetStore(baseDirectory: tempDirectory)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    /// A second store over the same directory — stands in for the next launch.
    private func relaunched() -> PresetStore {
        PresetStore(baseDirectory: tempDirectory)
    }

    func testListPresetsEmptyInitially() {
        XCTAssertTrue(store.listPresets().isEmpty)
    }

    func testUpsertCreatesNewPreset() {
        store.upsert(name: "Bog Hulk", maxHP: 7)

        let presets = store.listPresets()
        XCTAssertEqual(presets.count, 1)
        XCTAssertEqual(presets.first?.name, "Bog Hulk")
        XCTAssertEqual(presets.first?.maxHP, 7)
    }

    /// Fixtures here deliberately use a name that isn't in the built-in roster:
    /// upsert refuses to modify a built-in (see the read-only tests below), so a
    /// test of generic upsert behaviour named "Wolf" would be testing that
    /// instead.
    func testUpsertUpdatesExistingPresetCaseInsensitively() {
        store.upsert(name: "Bog Hulk", maxHP: 7)
        store.upsert(name: "bog hulk", maxHP: 9)

        let presets = store.listPresets()
        XCTAssertEqual(presets.count, 1, "should update the existing preset, not create a second one")
        XCTAssertEqual(presets.first?.maxHP, 9)
    }

    func testUpsertWithNilMaxHPKeepsPreviousValue() {
        store.upsert(name: "Bog Hulk", maxHP: 7)
        store.upsert(name: "Bog Hulk", maxHP: nil)

        XCTAssertEqual(store.preset(named: "Bog Hulk")?.maxHP, 7)
    }

    func testUpsertIgnoresBlankName() {
        store.upsert(name: "   ", maxHP: 5)
        XCTAssertTrue(store.listPresets().isEmpty)
    }

    func testPresetNamedFindsCaseInsensitiveMatch() {
        store.upsert(name: "Bog Hulk", maxHP: 13)
        XCTAssertEqual(store.preset(named: "BOG HULK")?.maxHP, 13)
        XCTAssertNil(store.preset(named: "Marsh Wight"))
    }

    func testDeletePreset() {
        store.upsert(name: "Bog Hulk", maxHP: 7)
        let id = store.listPresets().first!.id

        store.delete(id: id)

        XCTAssertTrue(store.listPresets().isEmpty)
    }

    func testInstallDefaultsPopulatesStarterPresets() {
        store.installDefaults()

        let presets = store.listPresets()
        XCTAssertEqual(presets.count, DefaultContent.creatures.count)
        XCTAssertNotNil(store.preset(named: "Wolf"))
    }

    func testInstalledDefaultsCarryFullStats() {
        store.installDefaults()

        let goblin = store.preset(named: "Wolf")
        XCTAssertEqual(goblin?.maxHP, 11)
        XCTAssertEqual(goblin?.armorClass, 12)
        XCTAssertEqual(goblin?.initiativeBonus, 2)
    }

    func testUpsertSetsInitiativeBonus() {
        store.upsert(name: "Bog Hulk", maxHP: 7, initiativeBonus: 2)
        XCTAssertEqual(store.preset(named: "Bog Hulk")?.initiativeBonus, 2)
    }

    func testUpsertWithNilInitiativeBonusKeepsPreviousValue() {
        store.upsert(name: "Bog Hulk", maxHP: 7, initiativeBonus: 2)
        store.upsert(name: "Bog Hulk", maxHP: 7, initiativeBonus: nil)

        XCTAssertEqual(store.preset(named: "Bog Hulk")?.initiativeBonus, 2)
    }

    /// Defaults are added *alongside* whatever the user has, not instead of it. Seeding "only when empty" meant a single
    /// custom creature before first launch permanently cost you the entire
    /// starter roster.
    func testInstallDefaultsAddsToExistingUserPresets() {
        store.upsert(name: "Custom Creature", maxHP: 20)

        store.installDefaults()

        let presets = store.listPresets()
        XCTAssertEqual(presets.count, DefaultContent.creatures.count + 1)
        XCTAssertNotNil(presets.first { $0.name == "Custom Creature" })
        XCTAssertNotNil(presets.first { $0.name == "Wolf" })
    }

    func testInstallDefaultsIsIdempotentAcrossLaunches() {
        store.installDefaults()
        relaunched().installDefaults()
        relaunched().installDefaults()

        XCTAssertEqual(store.listPresets().count, DefaultContent.creatures.count)
    }

    /// Built-in creatures are fixtures: the Creatures screen offers no way to
    /// delete one, and if a store somehow lacks one — an older version of the
    /// app, or the user renaming it into something of their own — the next launch
    /// puts it back.
    func testAMissingBuiltInIsRestoredOnNextLaunch() {
        store.installDefaults()
        let goblin = store.preset(named: "Wolf")!
        store.delete(id: goblin.id)

        relaunched().installDefaults()

        XCTAssertNotNil(store.preset(named: "Wolf"))
        XCTAssertEqual(store.listPresets().count, DefaultContent.creatures.count)
    }

    /// Renaming a built-in makes that copy yours (see `ListSections`) and the
    /// original comes back — you end up with both, rather than having quietly
    /// removed something from the built-in roster.
    func testRenamingABuiltInYieldsBothItAndTheOriginal() {
        store.installDefaults()
        var goblin = store.preset(named: "Wolf")!
        goblin.name = "Gobbo the Unkillable"
        store.save(goblin)

        relaunched().installDefaults()

        XCTAssertNotNil(store.preset(named: "Gobbo the Unkillable"))
        XCTAssertNotNil(store.preset(named: "Wolf"))
    }

    /// The upgrade path: someone using the app since before a creature existed
    /// should receive it, without their edits being disturbed.
    func testDefaultsAddedInALaterVersionReachAnExistingInstall() {
        // Stand in for "an older version installed only these".
        let alreadyShipped = Array(DefaultContent.creatures.prefix(5))
        for creature in alreadyShipped {
            store.upsert(name: creature.name, maxHP: creature.maxHP, armorClass: creature.armorClass, initiativeBonus: creature.initiativeBonus)
        }

        store.installDefaults()

        XCTAssertEqual(store.listPresets().count, DefaultContent.creatures.count, "the newly-added defaults should have arrived")
    }

    /// If the user already has a preset by a default's name, that name is
    /// recorded as offered and their version is left alone — no duplicate, no
    /// overwrite.
    func testInstallDefaultsNeverOverwritesAPresetWithTheSameName() {
        store.upsert(name: "goblin", maxHP: 999, armorClass: 99)

        store.installDefaults()

        let goblins = store.listPresets().filter { $0.name.lowercased() == "goblin" }
        XCTAssertEqual(goblins.count, 1, "installing defaults duplicated a creature the user already had")
        XCTAssertEqual(goblins.first?.maxHP, 999)
    }


    // MARK: - Built-ins are read-only

    /// Adding a combatant upserts a preset by name. Without a guard that quietly
    /// rewrites the built-in Goblin's stats — an edit to read-only content
    /// through the back door, from a screen that isn't even the Creatures list.
    func testUpsertDoesNotModifyABuiltInCreature() {
        store.installDefaults()

        store.upsert(name: "Wolf", maxHP: 999, armorClass: 99, initiativeBonus: 9)

        let goblin = store.preset(named: "Wolf")
        XCTAssertEqual(goblin?.maxHP, 11)
        XCTAssertEqual(goblin?.armorClass, 12)
        XCTAssertEqual(goblin?.initiativeBonus, 2)
    }

    func testUpsertStillUpdatesTheUsersOwnPresets() {
        store.upsert(name: "Hexed Duke", maxHP: 40)
        store.upsert(name: "Hexed Duke", maxHP: 55)

        XCTAssertEqual(store.preset(named: "Hexed Duke")?.maxHP, 55)
    }

    func testListStaysCurrentAfterSavingAndDeleting() {
        XCTAssertNil(store.listPresets().first { $0.name == "Cached One" })
        let preset = CreaturePreset(name: "Cached One", maxHP: 3)
        store.save(preset)
        XCTAssertNotNil(store.listPresets().first { $0.name == "Cached One" })
        var changed = preset
        changed.maxHP = 9
        store.save(changed)
        XCTAssertEqual(store.listPresets().first { $0.name == "Cached One" }?.maxHP, 9)
        store.delete(id: preset.id)
        XCTAssertNil(store.listPresets().first { $0.name == "Cached One" })
    }

    func testNewEntriesAreCreaturesUnlessSaidOtherwise() {
        XCTAssertFalse(CreaturePreset(name: "Plain").isPlayer)
        store.upsert(name: "Quiet One", maxHP: 5)
        XCTAssertEqual(store.preset(named: "Quiet One")?.isPlayer, false)
        store.upsert(name: "Hero", maxHP: 5, isPlayer: true)
        XCTAssertEqual(store.preset(named: "Hero")?.isPlayer, true)
    }

    func testCloneMakesAnEditableCopyUnderANewName() {
        store.installDefaults()
        let goblin = store.preset(named: "Wolf")!

        let copy = store.clone(goblin, named: "Goblin Warlord", isPlayer: false)

        XCTAssertEqual(copy.name, "Goblin Warlord", "the copy takes the name the owner typed")
        XCTAssertEqual(copy.maxHP, goblin.maxHP)
        XCTAssertEqual(copy.armorClass, goblin.armorClass)
        XCTAssertNotEqual(copy.id, goblin.id)
        XCTAssertFalse(copy.isBuiltIn, "a copy must be editable, so it can't count as built-in")
        XCTAssertNotNil(store.preset(named: "Wolf"), "duplicating must not disturb the original")
    }

    /// The clone sheet lets the owner change the numbers before saving; a blank
    /// field means no value, not "keep the original".
    func testCloneTakesTheEditedStats() {
        store.installDefaults()
        let wolf = store.preset(named: "Wolf")!

        let copy = store.clone(wolf, named: "Ember Wolf", isPlayer: false, stats: CloneStats(maxHP: 60, armorClass: nil, initiativeBonus: 3, challengeRating: nil))

        XCTAssertEqual(copy.maxHP, 60)
        XCTAssertNil(copy.armorClass)
        XCTAssertEqual(copy.initiativeBonus, 3)
        XCTAssertEqual(store.preset(named: "Ember Wolf")?.maxHP, 60, "the edited copy is what gets saved")
        XCTAssertEqual(store.preset(named: "Wolf")?.maxHP, wolf.maxHP, "the original is untouched")
    }

    func testCloneOfABuiltInKeepsItsChallengeRating() {
        store.installDefaults()
        let wolf = store.preset(named: "Wolf")!

        XCTAssertEqual(store.clone(wolf, named: "Ember Wolf", isPlayer: false).challengeRating, "1/4")
        XCTAssertEqual(
            store.clone(wolf, named: "Ember Hound", isPlayer: false, stats: CloneStats(maxHP: 5, armorClass: 9, initiativeBonus: 0, challengeRating: "2")).challengeRating,
            "2"
        )
    }

    func testCloneKeepsTheChosenCharacterKind() {
        store.installDefaults()
        let goblin = store.preset(named: "Wolf")!

        XCTAssertTrue(store.clone(goblin, named: "Goblin Scout", isPlayer: true).isPlayer)
        XCTAssertFalse(store.clone(goblin, named: "Goblin Raider", isPlayer: false).isPlayer)
    }

    /// The one-time clean-up across every kind of saved data, as CLAUDE.md asks of
    /// anything that deletes: the owner's creatures and characters go (approved
    /// 2026-11-17, before release); built-ins, sessions and encounters stay. A
    /// relaunch with the same defaults never runs it again.
    func testOneTimeCleanupKeepsEverythingButOwnCreaturesAndCharactersAcrossRelaunches() {
        let defaults = UserDefaults(suiteName: "cleanup-\(UUID().uuidString)")!
        let sessions = SessionStore(baseDirectory: tempDirectory.appendingPathComponent("Sessions"), userDefaults: defaults)
        let encounters = EncounterStore(baseDirectory: tempDirectory.appendingPathComponent("Encounters"))
        let presets = PresetStore(baseDirectory: tempDirectory.appendingPathComponent("Presets"))
        presets.installDefaults()
        presets.upsert(name: "My Ogre", maxHP: 40)
        presets.upsert(name: "Wren", maxHP: 22, isPlayer: true)
        sessions.save(SessionRecord(name: "Friday", combatants: [Combatant(name: "Wren", initiative: 12)], currentTurnIndex: 0))
        encounters.save(Encounter(name: "Swamp Ambush", entries: [EncounterEntry(name: "My Ogre")]))
        let builtInCount = presets.listPresets().filter(\.isBuiltIn).count

        presets.removeUserCreatures(once: "k", defaults: defaults)

        XCTAssertNil(presets.preset(named: "My Ogre"))
        XCTAssertNil(presets.preset(named: "Wren"))
        XCTAssertEqual(presets.listPresets().filter(\.isBuiltIn).count, builtInCount)
        XCTAssertEqual(sessions.listSavedSessions().map(\.name), ["Friday"])
        XCTAssertEqual(encounters.listEncounters().map(\.name), ["Swamp Ambush"])

        // Next launch: new stores over the same files and defaults.
        let relaunched = PresetStore(baseDirectory: tempDirectory.appendingPathComponent("Presets"))
        relaunched.upsert(name: "Wren", maxHP: 22, isPlayer: true)
        relaunched.removeUserCreatures(once: "k", defaults: defaults)
        let again = PresetStore(baseDirectory: tempDirectory.appendingPathComponent("Presets"))
        again.removeUserCreatures(once: "k", defaults: defaults)
        XCTAssertNotNil(again.preset(named: "Wren"))
    }

    // MARK: - Names

    /// Built-in status goes by name, so an entry of the owner's under a built-in's
    /// name would turn read-only and could not be deleted.
    func testABuiltInNameIsNotAvailable() {
        XCTAssertFalse(store.isNameAvailable("goblin boss"))
        XCTAssertFalse(store.isNameAvailable(" Goblin Boss "))
    }

    func testAnotherEntrysNameIsNotAvailable() {
        store.upsert(name: "Bog Hulk", maxHP: 7)
        XCTAssertFalse(store.isNameAvailable("bog hulk"))
    }

    func testAnEntryKeepsItsOwnName() {
        store.upsert(name: "Bog Hulk", maxHP: 7)
        let own = store.preset(named: "Bog Hulk")!
        XCTAssertTrue(store.isNameAvailable("Bog Hulk", excluding: own.id))
        XCTAssertTrue(store.isNameAvailable("Marsh Hag"))
        XCTAssertFalse(store.isNameAvailable("  "))
    }
}
