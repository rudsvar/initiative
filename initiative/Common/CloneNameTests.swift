import XCTest
@testable import initiative

final class CloneNameTests: XCTestCase {

    func testEmptyNameIsNotValid() {
        XCTAssertFalse(CloneName.isValid("", avoiding: []))
    }

    func testBlankNameIsNotValid() {
        XCTAssertFalse(CloneName.isValid("   ", avoiding: []))
    }

    func testNameAlreadyInUseIsNotValid() {
        XCTAssertFalse(CloneName.isValid("Goblin", avoiding: ["Goblin"]))
    }

    func testNameInUseIgnoresCaseAndSpaces() {
        XCTAssertFalse(CloneName.isValid("  goblin ", avoiding: ["Goblin"]))
    }

    func testNewNameIsValid() {
        XCTAssertTrue(CloneName.isValid("Hobgoblin Captain", avoiding: ["Goblin"]))
    }
}
