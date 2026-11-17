import XCTest
@testable import initiative

/// The add-a-creature form, shared by Add Combatant and an encounter's Add Creature.
final class CombatantDraftTests: XCTestCase {
    private let wolf = CreaturePreset(name: "Wolf", maxHP: 11, armorClass: 12, initiativeBonus: 2)
    private let wren = CreaturePreset(name: "Wren", maxHP: 22, armorClass: 14, initiativeBonus: 3, isPlayer: true)

    func testChoosingFillsTheFormAndTheKind() {
        var draft = CombatantDraft()
        draft.choose(wren)
        XCTAssertEqual(draft.name, "Wren")
        XCTAssertEqual(draft.maxHP, 22)
        XCTAssertEqual(draft.armorClass, 14)
        XCTAssertEqual(draft.initiativeBonus, 3)
        XCTAssertTrue(draft.isPlayer)
        XCTAssertEqual(draft.chosen, wren)
    }

    /// Typing a known name fills only the empty fields; what was typed stays.
    func testTypingAKnownNameFillsOnlyEmptyFields() {
        var draft = CombatantDraft()
        draft.hpText = "30"
        draft.name = "wolf"
        draft.nameChanged(matching: wolf)
        XCTAssertEqual(draft.maxHP, 30)
        XCTAssertEqual(draft.armorClass, 12)
        XCTAssertEqual(draft.initiativeBonus, 2)
        XCTAssertFalse(draft.isPlayer)
    }

    /// A name that matches nothing is a new creature, not whatever was picked before.
    func testTypingOverAChoiceForgetsIt() {
        var draft = CombatantDraft()
        draft.choose(wren)
        draft.name = "Wrenna"
        draft.nameChanged(matching: nil)
        XCTAssertNil(draft.chosen)
        XCTAssertNil(draft.initiativeBonus)
        XCTAssertFalse(draft.isPlayer)
    }

    func testNumbersAndCount() {
        var draft = CombatantDraft()
        XCTAssertFalse(draft.isValid)
        draft.name = "  Ogre "
        draft.countText = "0"
        XCTAssertTrue(draft.isValid)
        XCTAssertEqual(draft.trimmedName, "Ogre")
        XCTAssertEqual(draft.count, 1)
        draft.countText = "3"
        XCTAssertEqual(draft.count, 3)
        XCTAssertNil(draft.maxHP)
    }
}
