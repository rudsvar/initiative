import XCTest
@testable import initiative

final class SessionStoreTests: XCTestCase {
    var store: SessionStore!
    var tempDirectory: URL!
    var defaults: UserDefaults!
    var defaultsSuiteName: String!

    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defaultsSuiteName = "SessionStoreTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: defaultsSuiteName)
        store = SessionStore(baseDirectory: tempDirectory, userDefaults: defaults)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        UserDefaults().removePersistentDomain(forName: defaultsSuiteName)
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

    func testResumableSessionNilWhenNoneActive() {
        XCTAssertNil(store.resumableSession())
    }

    func testResumableSessionReturnsLastActive() {
        let participant = Participant(name: "Hero", initiative: 15)
        let record = SessionRecord(name: "In Progress", participants: [participant], currentTurnIndex: 0)
        store.save(record)
        store.setLastActiveSessionID(record.id)

        let resumed = store.resumableSession()
        XCTAssertEqual(resumed?.participants.first?.name, "Hero")
    }

    func testResumableSessionNilAfterDeletingLastActive() {
        let record = SessionRecord(name: "In Progress", participants: [], currentTurnIndex: 0)
        store.save(record)
        store.setLastActiveSessionID(record.id)

        store.delete(id: record.id)

        XCTAssertNil(store.resumableSession())
    }

    func testClearLastActiveSessionID() {
        let record = SessionRecord(name: "In Progress", participants: [], currentTurnIndex: 0)
        store.save(record)
        store.setLastActiveSessionID(record.id)

        store.clearLastActiveSessionID()

        XCTAssertNil(store.resumableSession())
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
