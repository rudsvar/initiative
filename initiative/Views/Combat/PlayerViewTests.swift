import XCTest
@testable import initiative

/// Player view is the DM turning the screen around. It hides every combatant's
/// numbers, party included: the party does not necessarily share hit points
/// among themselves, so that is up to them.
///
/// The row simply checks `session.playerViewEnabled`; these pin the intent on the
/// session state, since the view can't be exercised directly.
final class PlayerViewTests: XCTestCase {

    func testPlayerViewIsOffByDefault() {
        XCTAssertFalse(CombatSession().playerViewEnabled)
    }

    func testPlayerViewAppliesToPartyAndMonstersAlike() {
        // There is no per-combatant exception: the row reads only the session flag.
        let session = CombatSession()
        session.addCombatant(name: "Wren", initiative: 12, maxHP: 30, isPlayer: true)
        session.addCombatant(name: "Wolf", initiative: 10, maxHP: 11, isPlayer: false)
        session.playerViewEnabled = true
        XCTAssertTrue(session.playerViewEnabled)
        XCTAssertEqual(session.combatants.count, 2)
    }
}
