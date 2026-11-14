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
    /// test of generic upsert behaviour named "Goblin" would be testing that
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
        XCTAssertNotNil(store.preset(named: "Goblin"))
    }

    func testInstalledDefaultsCarryFullStats() {
        store.installDefaults()

        let goblin = store.preset(named: "Goblin")
        XCTAssertEqual(goblin?.maxHP, 8)
        XCTAssertEqual(goblin?.armorClass, 13)
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
        XCTAssertNotNil(presets.first { $0.name == "Goblin" })
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
        let goblin = store.preset(named: "Goblin")!
        store.delete(id: goblin.id)

        relaunched().installDefaults()

        XCTAssertNotNil(store.preset(named: "Goblin"))
        XCTAssertEqual(store.listPresets().count, DefaultContent.creatures.count)
    }

    /// Renaming a built-in makes that copy yours (see `ListSections`) and the
    /// original comes back — you end up with both, rather than having quietly
    /// removed something from the built-in roster.
    func testRenamingABuiltInYieldsBothItAndTheOriginal() {
        store.installDefaults()
        var goblin = store.preset(named: "Goblin")!
        goblin.name = "Gobbo the Unkillable"
        store.save(goblin)

        relaunched().installDefaults()

        XCTAssertNotNil(store.preset(named: "Gobbo the Unkillable"))
        XCTAssertNotNil(store.preset(named: "Goblin"))
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

        store.upsert(name: "Goblin", maxHP: 999, armorClass: 99, initiativeBonus: 9)

        let goblin = store.preset(named: "Goblin")
        XCTAssertEqual(goblin?.maxHP, 8)
        XCTAssertEqual(goblin?.armorClass, 13)
        XCTAssertEqual(goblin?.initiativeBonus, 2)
    }

    func testUpsertStillUpdatesTheUsersOwnPresets() {
        store.upsert(name: "Hexed Duke", maxHP: 40)
        store.upsert(name: "Hexed Duke", maxHP: 55)

        XCTAssertEqual(store.preset(named: "Hexed Duke")?.maxHP, 55)
    }

    func testDuplicateMakesAnEditableCopyUnderANewName() {
        store.installDefaults()
        let goblin = store.preset(named: "Goblin")!

        let copy = store.duplicate(goblin)

        XCTAssertEqual(copy.name, "Goblin Copy")
        XCTAssertEqual(copy.maxHP, goblin.maxHP)
        XCTAssertEqual(copy.armorClass, goblin.armorClass)
        XCTAssertNotEqual(copy.id, goblin.id)
        XCTAssertFalse(copy.isBuiltIn, "a copy must be editable, so it can't count as built-in")
        XCTAssertNotNil(store.preset(named: "Goblin"), "duplicating must not disturb the original")
    }

    func testDuplicatingTwiceDoesNotCollide() {
        store.installDefaults()
        let goblin = store.preset(named: "Goblin")!

        XCTAssertEqual(store.duplicate(goblin).name, "Goblin Copy")
        XCTAssertEqual(store.duplicate(goblin).name, "Goblin Copy 2")
    }
}
