#if DEBUG
import XCTest
@testable import initiative

/// A dying test scenario must look like a real dying character: at 0 HP, with
/// the tally on. A scenario that sets the tally at full HP shows a healthy number
/// beside a dying mark, which is not a state the rules can reach.
final class DyingScenarioTests: XCTestCase {

    func testDyingScenariosStartAtZeroHP() {
        for name in ["dyingCharacterKeepsItsTurns", "dyingWithTally", "startOfTurnPromptMovesTheMarker", "lastFailedSaveKeepsTheTurn"] {
            let session = TestCombats.scenarios[name]!()
            let dying = session.combatants.filter { $0.deathSaves != nil }
            XCTAssertFalse(dying.isEmpty, "\(name) has no dying combatant")
            for combatant in dying {
                XCTAssertEqual(combatant.currentHP, 0, "\(name): \(combatant.name) should be at 0 HP while dying")
            }
        }
    }
}
#endif
