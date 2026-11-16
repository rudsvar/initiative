#if DEBUG
import XCTest
@testable import initiative

final class TestCharactersTests: XCTestCase {
    func testDebugBuildsGetTheTestCharactersOnce() {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = PresetStore(baseDirectory: directory)
        store.installTestCharacters()
        store.installTestCharacters()
        let characters = store.listPresets().filter { $0.isPlayer }
        XCTAssertEqual(characters.map(\.name).sorted(), ["Aria", "Brom", "Cael"])
    }

    func testTestCharactersAreNeverBuiltIn() {
        XCTAssertTrue(TestCharacters.all.allSatisfy { !$0.isBuiltIn })
    }
}
#endif
