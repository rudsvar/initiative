import XCTest
@testable import initiative

final class EncounterStoreTests: XCTestCase {
    var store: EncounterStore!
    var tempDirectory: URL!
    private var suiteName = ""
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        suiteName = "EncounterStoreTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        store = EncounterStore(baseDirectory: tempDirectory, defaults: defaults)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    /// A second store over the same directory and ledger — the next launch.
    private func relaunched() -> EncounterStore {
        EncounterStore(baseDirectory: tempDirectory, defaults: defaults)
    }

    // MARK: - Default content

    func testInstallNewDefaultsPopulatesStarterEncounters() {
        store.installNewDefaults()

        XCTAssertEqual(store.listEncounters().count, DefaultContent.encounters.count)
    }

    /// Encounters are stored as stat snapshots, so installing one has to resolve
    /// its lineup against the creature table rather than saving bare names — an
    /// encounter with no HP/AC would start a session with empty combatants.
    func testInstalledEncountersCarryResolvedCreatureStats() {
        store.installNewDefaults()

        let ambush = store.listEncounters().first { $0.name == "Goblin Ambush" }
        let goblins = ambush?.entries.first { $0.name == "Goblin" }
        XCTAssertEqual(goblins?.maxHP, 7)
        XCTAssertEqual(goblins?.armorClass, 15)
        XCTAssertEqual(goblins?.count, 4)
    }

    func testInstallNewDefaultsAddsToExistingUserEncounters() {
        store.save(Encounter(name: "My Own Fight", entries: [EncounterEntry(name: "Thing", maxHP: 5)]))

        store.installNewDefaults()

        let names = store.listEncounters().map(\.name)
        XCTAssertEqual(names.count, DefaultContent.encounters.count + 1)
        XCTAssertTrue(names.contains("My Own Fight"))
    }

    func testInstallNewDefaultsIsIdempotentAcrossLaunches() {
        store.installNewDefaults()
        relaunched().installNewDefaults()

        XCTAssertEqual(store.listEncounters().count, DefaultContent.encounters.count)
    }

    func testADeletedDefaultEncounterDoesNotComeBack() {
        store.installNewDefaults()
        let doomed = store.listEncounters().first!
        store.delete(id: doomed.id)

        relaunched().installNewDefaults()

        XCTAssertNil(store.listEncounters().first { $0.name == doomed.name })
    }


    func testListEncountersEmptyInitially() {
        XCTAssertTrue(store.listEncounters().isEmpty)
    }

    func testSaveAndListEncounter() {
        let encounter = Encounter(
            name: "Goblin Ambush",
            entries: [EncounterEntry(name: "Goblin", maxHP: 7, count: 3)]
        )
        store.save(encounter)

        let listed = store.listEncounters()
        XCTAssertEqual(listed.count, 1)
        XCTAssertEqual(listed.first?.name, "Goblin Ambush")
        XCTAssertEqual(listed.first?.entries.first?.count, 3)
    }

    func testDeleteEncounter() {
        let encounter = Encounter(name: "Goblin Ambush")
        store.save(encounter)

        store.delete(id: encounter.id)

        XCTAssertTrue(store.listEncounters().isEmpty)
    }

    func testEncountersSortedByNameCaseInsensitive() {
        store.save(Encounter(name: "zombies"))
        store.save(Encounter(name: "Ambush"))

        let listed = store.listEncounters()
        XCTAssertEqual(listed.map { $0.name }, ["Ambush", "zombies"])
    }

    func testEncounterEntryCountClampsToAtLeastOne() {
        let entry = EncounterEntry(name: "Goblin", count: 0)
        XCTAssertEqual(entry.count, 1)
    }
}
