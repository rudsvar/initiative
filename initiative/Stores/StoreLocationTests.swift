import XCTest
@testable import initiative

/// Each store must find the files earlier builds wrote, where they wrote them.
/// The files here are placed by hand at those paths, not written by the stores,
/// so a change to a folder or file name fails here instead of on someone's phone.
final class StoreLocationTests: XCTestCase {
    private var documents: URL!

    override func setUp() {
        super.setUp()
        documents = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: documents)
        super.tearDown()
    }

    private func place(_ json: String, at path: String) throws {
        let url = documents.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(json.utf8).write(to: url)
    }

    func testSessionsAreReadFromSavedSessions() throws {
        let id = UUID()
        try place("""
        {"id":"\(id.uuidString)","name":"Friday","savedAt":0,"combatants":[],"currentTurnIndex":0}
        """, at: "SavedSessions/\(id.uuidString).json")
        // The session store is given the Documents folder itself.
        XCTAssertEqual(SessionStore(baseDirectory: documents).listSavedSessions().map(\.name), ["Friday"])
    }

    func testPresetsAreReadFromPresets() throws {
        let id = UUID()
        try place("""
        {"id":"\(id.uuidString)","name":"Wren","maxHP":22,"isPlayer":true}
        """, at: "Presets/\(id.uuidString).json")
        // The preset and encounter stores are given their own folder.
        let store = PresetStore(baseDirectory: documents.appendingPathComponent("Presets"))
        XCTAssertEqual(store.listPresets().map(\.name), ["Wren"])
    }

    func testEncountersAreReadFromEncounters() throws {
        let id = UUID()
        try place("""
        {"id":"\(id.uuidString)","name":"Swamp Ambush","entries":[]}
        """, at: "Encounters/\(id.uuidString).json")
        let store = EncounterStore(baseDirectory: documents.appendingPathComponent("Encounters"))
        XCTAssertEqual(store.listEncounters().map(\.name), ["Swamp Ambush"])
    }

    /// A file this build can't decode is left alone, never deleted.
    func testAFileThatDoesNotDecodeIsKept() throws {
        try place("{\"future\":true}", at: "Encounters/\(UUID().uuidString).json")
        let store = EncounterStore(baseDirectory: documents.appendingPathComponent("Encounters"))
        XCTAssertTrue(store.listEncounters().isEmpty)
        store.save(Encounter(name: "New"))
        let files = try FileManager.default.contentsOfDirectory(atPath: documents.appendingPathComponent("Encounters").path)
        XCTAssertEqual(files.count, 2)
    }
}
