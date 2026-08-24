import XCTest
@testable import initiative

final class UniqueNameTests: XCTestCase {

    func testFirstCopyIsUnnumbered() {
        XCTAssertEqual(UniqueName.forCopy(of: "Goblin", avoiding: ["Goblin"]), "Goblin Copy")
    }

    func testSubsequentCopiesAreNumberedFromTwo() {
        XCTAssertEqual(
            UniqueName.forCopy(of: "Goblin", avoiding: ["Goblin", "Goblin Copy"]),
            "Goblin Copy 2"
        )
        XCTAssertEqual(
            UniqueName.forCopy(of: "Goblin", avoiding: ["Goblin", "Goblin Copy", "Goblin Copy 2"]),
            "Goblin Copy 3"
        )
    }

    /// Gaps are filled rather than skipped past — deleting "Goblin Copy 2" and
    /// copying again should reuse the free number, not climb forever.
    func testAFreedNumberIsReused() {
        XCTAssertEqual(
            UniqueName.forCopy(of: "Goblin", avoiding: ["Goblin Copy", "Goblin Copy 3"]),
            "Goblin Copy 2"
        )
    }

    /// The stores compare names case-insensitively, so this has to as well or a
    /// "copy" could be created that the store then treats as a duplicate.
    func testExistingNamesMatchRegardlessOfCase() {
        XCTAssertEqual(
            UniqueName.forCopy(of: "Goblin", avoiding: ["goblin copy"]),
            "Goblin Copy 2"
        )
    }

    func testCopyingACopyKeepsExtending() {
        XCTAssertEqual(
            UniqueName.forCopy(of: "Goblin Copy", avoiding: ["Goblin", "Goblin Copy"]),
            "Goblin Copy Copy"
        )
    }

    func testSurroundingWhitespaceIsTrimmed() {
        XCTAssertEqual(UniqueName.forCopy(of: "  Goblin  ", avoiding: []), "Goblin Copy")
    }
}
