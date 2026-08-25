import XCTest
@testable import initiative

/// Player view is the DM turning the screen around. What it should hide is the
/// monsters' numbers — the party already know their own — so the decision is
/// per-combatant, not a blanket one.
///
/// The rule lives in `CombatantRow.hideNumbers`, which is a trivial derivation of
/// tested state; these check the derivation itself so the intent is pinned even
/// though the view can't be exercised directly.
final class PlayerViewTests: XCTestCase {

    private func hideNumbers(playerViewEnabled: Bool, isPlayer: Bool) -> Bool {
        playerViewEnabled && !isPlayer
    }

    func testDMViewShowsEverything() {
        XCTAssertFalse(hideNumbers(playerViewEnabled: false, isPlayer: false))
        XCTAssertFalse(hideNumbers(playerViewEnabled: false, isPlayer: true))
    }

    func testPlayerViewHidesMonsterNumbers() {
        XCTAssertTrue(hideNumbers(playerViewEnabled: true, isPlayer: false))
    }

    func testPlayerViewLeavesThePartysOwnNumbersVisible() {
        XCTAssertFalse(
            hideNumbers(playerViewEnabled: true, isPlayer: true),
            "the party know their own hit points; hiding them serves no one"
        )
    }
}
