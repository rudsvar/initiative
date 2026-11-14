import XCTest
@testable import initiative

final class EncounterStoreTests: XCTestCase {
    var store: EncounterStore!
    var tempDirectory: URL!
    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        store = EncounterStore(baseDirectory: tempDirectory)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    /// A second store over the same directory — the next launch.
    private func relaunched() -> EncounterStore {
        EncounterStore(baseDirectory: tempDirectory)
    }

    // MARK: - Default content

    func testInstallDefaultsPopulatesTheStarterEncounters() {
        store.installDefaults()

        XCTAssertEqual(store.listEncounters().count, DefaultContent.encounters.count)
    }

    /// Encounters are stored as stat snapshots, so installing one has to resolve
    /// its lineup against the creature table rather than saving bare names — an
    /// encounter with no HP/AC would start a session with empty combatants.
    func testInstalledEncountersCarryResolvedCreatureStats() {
        store.installDefaults()

        let ambush = store.listEncounters().first { $0.name == "Goblin Ambush" }
        let goblins = ambush?.entries.first { $0.name == "Goblin" }
        XCTAssertEqual(goblins?.maxHP, 8)
        XCTAssertEqual(goblins?.armorClass, 13)
        XCTAssertEqual(goblins?.count, 4)
    }

    func testInstallDefaultsAddsToExistingUserEncounters() {
        store.save(Encounter(name: "My Own Fight", entries: [EncounterEntry(name: "Thing", maxHP: 5)]))

        store.installDefaults()

        let names = store.listEncounters().map(\.name)
        XCTAssertEqual(names.count, DefaultContent.encounters.count + 1)
        XCTAssertTrue(names.contains("My Own Fight"))
    }

    func testInstallDefaultsIsIdempotentAcrossLaunches() {
        store.installDefaults()
        relaunched().installDefaults()

        XCTAssertEqual(store.listEncounters().count, DefaultContent.encounters.count)
    }

    /// Built-in encounters are fixtures — the screen offers no way to delete one,
    /// and anything missing is restored on the next launch.
    func testAMissingBuiltInEncounterIsRestored() {
        store.installDefaults()
        let doomed = store.listEncounters().first!
        store.delete(id: doomed.id)

        relaunched().installDefaults()

        XCTAssertNotNil(store.listEncounters().first { $0.name == doomed.name })
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

    // MARK: - Built-ins are read-only

    func testDuplicateMakesAnEditableCopyUnderANewName() {
        store.installDefaults()
        let ambush = store.listEncounters().first { $0.name == "Goblin Ambush" }!

        let copy = store.duplicate(ambush)

        XCTAssertEqual(copy.name, "Goblin Ambush Copy")
        XCTAssertEqual(copy.entries.map(\.name), ambush.entries.map(\.name))
        XCTAssertEqual(copy.entries.map(\.count), ambush.entries.map(\.count))
        XCTAssertFalse(copy.isBuiltIn)
        XCTAssertNotNil(store.listEncounters().first { $0.name == "Goblin Ambush" })
    }

    /// Entries are snapshots, so a copy needs its own entry identities — sharing
    /// them would make SwiftUI's list diffing treat two encounters' rows as the
    /// same rows.
    func testDuplicatedEntriesGetFreshIdentities() {
        store.installDefaults()
        let ambush = store.listEncounters().first { $0.name == "Goblin Ambush" }!

        let copy = store.duplicate(ambush)

        XCTAssertTrue(Set(copy.entries.map(\.id)).isDisjoint(with: Set(ambush.entries.map(\.id))))
    }
}
