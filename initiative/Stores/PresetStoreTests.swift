import XCTest
@testable import initiative

final class PresetStoreTests: XCTestCase {
    var store: PresetStore!
    var tempDirectory: URL!
    private var suiteName = ""
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        // A scratch UserDefaults per test: the install ledger lives there, and a
        // shared one would let one test's "already installed" record decide
        // another test's outcome.
        suiteName = "PresetStoreTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        store = PresetStore(baseDirectory: tempDirectory, defaults: defaults)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    /// A second store over the same directory and ledger — stands in for the next
    /// launch of the app.
    private func relaunched() -> PresetStore {
        PresetStore(baseDirectory: tempDirectory, defaults: defaults)
    }

    func testListPresetsEmptyInitially() {
        XCTAssertTrue(store.listPresets().isEmpty)
    }

    func testUpsertCreatesNewPreset() {
        store.upsert(name: "Goblin", maxHP: 7)

        let presets = store.listPresets()
        XCTAssertEqual(presets.count, 1)
        XCTAssertEqual(presets.first?.name, "Goblin")
        XCTAssertEqual(presets.first?.maxHP, 7)
    }

    func testUpsertUpdatesExistingPresetCaseInsensitively() {
        store.upsert(name: "Goblin", maxHP: 7)
        store.upsert(name: "goblin", maxHP: 9)

        let presets = store.listPresets()
        XCTAssertEqual(presets.count, 1, "should update the existing preset, not create a second one")
        XCTAssertEqual(presets.first?.maxHP, 9)
    }

    func testUpsertWithNilMaxHPKeepsPreviousValue() {
        store.upsert(name: "Goblin", maxHP: 7)
        store.upsert(name: "Goblin", maxHP: nil)

        XCTAssertEqual(store.preset(named: "Goblin")?.maxHP, 7)
    }

    func testUpsertIgnoresBlankName() {
        store.upsert(name: "   ", maxHP: 5)
        XCTAssertTrue(store.listPresets().isEmpty)
    }

    func testPresetNamedFindsCaseInsensitiveMatch() {
        store.upsert(name: "Skeleton", maxHP: 13)
        XCTAssertEqual(store.preset(named: "SKELETON")?.maxHP, 13)
        XCTAssertNil(store.preset(named: "Zombie"))
    }

    func testDeletePreset() {
        store.upsert(name: "Goblin", maxHP: 7)
        let id = store.listPresets().first!.id

        store.delete(id: id)

        XCTAssertTrue(store.listPresets().isEmpty)
    }

    func testInstallNewDefaultsPopulatesStarterPresets() {
        store.installNewDefaults()

        let presets = store.listPresets()
        XCTAssertEqual(presets.count, DefaultContent.creatures.count)
        XCTAssertNotNil(store.preset(named: "Goblin"))
    }

    func testInstalledDefaultsCarryFullStats() {
        store.installNewDefaults()

        let goblin = store.preset(named: "Goblin")
        XCTAssertEqual(goblin?.maxHP, 7)
        XCTAssertEqual(goblin?.armorClass, 15)
        XCTAssertEqual(goblin?.initiativeBonus, 2)
    }

    func testUpsertSetsInitiativeBonus() {
        store.upsert(name: "Goblin", maxHP: 7, initiativeBonus: 2)
        XCTAssertEqual(store.preset(named: "Goblin")?.initiativeBonus, 2)
    }

    func testUpsertWithNilInitiativeBonusKeepsPreviousValue() {
        store.upsert(name: "Goblin", maxHP: 7, initiativeBonus: 2)
        store.upsert(name: "Goblin", maxHP: 7, initiativeBonus: nil)

        XCTAssertEqual(store.preset(named: "Goblin")?.initiativeBonus, 2)
    }

    /// The whole point of the ledger: defaults are added *alongside* whatever the
    /// user has, not instead of it. Seeding "only when empty" meant a single
    /// custom creature before first launch permanently cost you the entire
    /// starter roster.
    func testInstallNewDefaultsAddsToExistingUserPresets() {
        store.upsert(name: "Custom Creature", maxHP: 20)

        store.installNewDefaults()

        let presets = store.listPresets()
        XCTAssertEqual(presets.count, DefaultContent.creatures.count + 1)
        XCTAssertNotNil(presets.first { $0.name == "Custom Creature" })
        XCTAssertNotNil(presets.first { $0.name == "Goblin" })
    }

    func testInstallNewDefaultsIsIdempotentAcrossLaunches() {
        store.installNewDefaults()
        relaunched().installNewDefaults()
        relaunched().installNewDefaults()

        XCTAssertEqual(store.listPresets().count, DefaultContent.creatures.count)
    }

    /// A default deleted on purpose must stay deleted — this is the failure mode
    /// that a naive "install anything missing" version would have.
    func testADeletedDefaultDoesNotComeBackOnNextLaunch() {
        store.installNewDefaults()
        let goblin = store.preset(named: "Goblin")!
        store.delete(id: goblin.id)

        relaunched().installNewDefaults()

        XCTAssertNil(store.preset(named: "Goblin"), "a deliberately deleted default was reinstalled")
    }

    /// The upgrade path: someone who has been using the app since before a
    /// creature existed should receive it, without their edits being disturbed.
    func testDefaultsAddedInALaterVersionReachAnExistingInstall() {
        // Stand in for "an older version installed only these": mark part of the
        // roster as already offered, and give the user an edited copy of one.
        let alreadyShipped = Array(DefaultContent.creatures.prefix(5))
        for creature in alreadyShipped {
            store.upsert(name: creature.name, maxHP: creature.maxHP, armorClass: creature.armorClass, initiativeBonus: creature.initiativeBonus)
        }
        store.upsert(name: alreadyShipped[0].name, maxHP: 999)
        defaults.set(alreadyShipped.map { $0.name.lowercased() }, forKey: "installedDefaultCreatures")

        store.installNewDefaults()

        XCTAssertEqual(store.listPresets().count, DefaultContent.creatures.count, "the newly-added defaults should have arrived")
        XCTAssertEqual(store.preset(named: alreadyShipped[0].name)?.maxHP, 999, "an edited preset must survive the upgrade")
    }

    /// If the user already has a preset by a default's name, that name is
    /// recorded as offered and their version is left alone — no duplicate, no
    /// overwrite.
    func testInstallNewDefaultsNeverOverwritesAPresetWithTheSameName() {
        store.upsert(name: "goblin", maxHP: 999, armorClass: 99)

        store.installNewDefaults()

        let goblins = store.listPresets().filter { $0.name.lowercased() == "goblin" }
        XCTAssertEqual(goblins.count, 1, "installing defaults duplicated a creature the user already had")
        XCTAssertEqual(goblins.first?.maxHP, 999)
    }

    func testRestoreMissingDefaultsAddsBackMissingOnesWithoutTouchingExisting() {
        store.upsert(name: "Custom Creature", maxHP: 20)
        // Simulate a default that was already added and then customized —
        // restoreMissingDefaults must not clobber it.
        store.upsert(name: "Goblin", maxHP: 999)

        store.restoreMissingDefaults()

        let presets = store.listPresets()
        XCTAssertEqual(presets.count, DefaultContent.creatures.count + 1, "should add every missing default plus keep the custom one")
        XCTAssertEqual(presets.first { $0.name == "Goblin" }?.maxHP, 999, "existing preset with a default's name must not be overwritten")
        XCTAssertNotNil(presets.first { $0.name == "Skeleton" }, "a default that was never added should now be present")
    }

    func testRestoreMissingDefaultsIsIdempotent() {
        store.restoreMissingDefaults()
        store.restoreMissingDefaults()

        XCTAssertEqual(store.listPresets().count, DefaultContent.creatures.count, "running twice shouldn't duplicate defaults")
    }

    /// Restore is the one action allowed to override a deletion — but only that
    /// once. Having brought a default back, the ledger must not then treat it as
    /// deletable-and-restorable on every subsequent launch.
    func testRestoreThenRelaunchDoesNotReinstallASubsequentDeletion() {
        store.installNewDefaults()
        store.restoreMissingDefaults()
        let goblin = store.preset(named: "Goblin")!
        store.delete(id: goblin.id)

        relaunched().installNewDefaults()

        XCTAssertNil(store.preset(named: "Goblin"))
    }
}
