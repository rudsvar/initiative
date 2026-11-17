#if DEBUG
import XCTest
@testable import initiative

final class DebugScenariosViewTests: XCTestCase {
    func testScenarioNamesReadAsSentences() {
        XCTAssertEqual(DebugScenariosView.title(for: "deadCreatureIsSkipped"), "Dead creature is skipped")
        XCTAssertEqual(DebugScenariosView.title(for: "wolfWithChanges"), "Wolf with changes")
        XCTAssertEqual(DebugScenariosView.title(for: "hpAndACChangesShowUntilTurnStarts"), "HP and AC changes show until turn starts")
    }
}
#endif
