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
