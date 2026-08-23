import XCTest
@testable import initiative

final class SessionStoreTests: XCTestCase {
    var store: SessionStore!
    var tempDirectory: URL!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        store = SessionStore(baseDirectory: tempDirectory)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }

    func testListSavedSessionsEmptyInitially() {
        XCTAssertTrue(store.listSavedSessions().isEmpty)
    }

    func testSaveAndListSession() {
        let record = SessionRecord(name: "Goblin Ambush", participants: [], currentTurnIndex: 0)
        store.save(record)

        let listed = store.listSavedSessions()
        XCTAssertEqual(listed.count, 1)
        XCTAssertEqual(listed.first?.name, "Goblin Ambush")
    }

    func testDeleteSession() {
        let record = SessionRecord(name: "Ambush", participants: [], currentTurnIndex: 0)
        store.save(record)

        store.delete(id: record.id)

        XCTAssertTrue(store.listSavedSessions().isEmpty)
    }

    func testAutosaveRoundTrip() {
        XCTAssertNil(store.loadAutosave())

        let participant = Participant(name: "Hero", initiative: 15)
        let record = SessionRecord(name: "In Progress", participants: [participant], currentTurnIndex: 0)
        store.saveAutosave(record)

        let loaded = store.loadAutosave()
        XCTAssertEqual(loaded?.participants.first?.name, "Hero")
    }

    func testClearAutosave() {
        let record = SessionRecord(name: "In Progress", participants: [], currentTurnIndex: 0)
        store.saveAutosave(record)

        store.clearAutosave()

        XCTAssertNil(store.loadAutosave())
    }

    func testSessionsAreSortedNewestFirst() {
        let older = SessionRecord(name: "Older", savedAt: Date(timeIntervalSince1970: 0), participants: [], currentTurnIndex: 0)
        let newer = SessionRecord(name: "Newer", savedAt: Date(timeIntervalSince1970: 1000), participants: [], currentTurnIndex: 0)
        store.save(older)
        store.save(newer)

        let listed = store.listSavedSessions()
        XCTAssertEqual(listed.first?.name, "Newer")
        XCTAssertEqual(listed.last?.name, "Older")
    }
}
