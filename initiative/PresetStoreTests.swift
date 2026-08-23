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

    func testSeedDefaultsIfEmptyPopulatesStarterPresets() {
        store.seedDefaultsIfEmpty()

        let presets = store.listPresets()
        XCTAssertEqual(presets.count, CreaturePreset.defaults.count)
        XCTAssertNotNil(store.preset(named: "Goblin"))
    }

    func testSeedDefaultsIfEmptyDoesNothingWhenPresetsExist() {
        store.upsert(name: "Custom Creature", maxHP: 20)

        store.seedDefaultsIfEmpty()

        let presets = store.listPresets()
        XCTAssertEqual(presets.count, 1, "should not add defaults on top of existing presets")
        XCTAssertEqual(presets.first?.name, "Custom Creature")
    }
}
