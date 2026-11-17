import XCTest
@testable import initiative

/// Temporary armor class: a buffer for this fight. A new grant replaces the old one.
final class TemporaryACTests: XCTestCase {

    func testNewGrantReplacesTheOldOne() {
        let session = TestCombats.wrenWithArmorClass()
        let wren = session.combatants[0].id
        session.grantTemporaryAC(to: wren, amount: 2)
        session.grantTemporaryAC(to: wren, amount: 4)
        XCTAssertEqual(session.combatants[0].temporaryAC, 4)
    }

    func testZeroGrantDoesNothing() {
        let session = TestCombats.wrenWithArmorClass()
        let wren = session.combatants[0].id
        session.grantTemporaryAC(to: wren, amount: 0)
        XCTAssertNil(session.combatants[0].temporaryAC)
    }

    /// A combatant saved before temporary AC existed has no such key, and decodes
    /// with none.
    func testSavedCombatantWithoutTemporaryACDecodesWithNone() throws {
        let json = """
        {"id":"\(UUID().uuidString)","name":"Wren","initiative":12,"effects":[],"armorClass":14}
        """.data(using: .utf8)!
        let combatant = try JSONDecoder().decode(Combatant.self, from: json)
        XCTAssertNil(combatant.temporaryAC)
        XCTAssertEqual(combatant.armorClass, 14)
    }

    func testTemporaryACRoundTrips() throws {
        var combatant = Combatant(name: "Wren", initiative: 12, armorClass: 14)
        combatant.temporaryAC = 3
        let decoded = try JSONDecoder().decode(Combatant.self, from: JSONEncoder().encode(combatant))
        XCTAssertEqual(decoded.temporaryAC, 3)
    }

    /// Temporary AC counts: the armor class the table uses is base plus temporary.
    func testArmorClassInPlayIncludesTemporaryAC() {
        let session = TestCombats.wrenWithArmorClass()
        let wren = session.combatants[0].id
        let base = session.combatants[0].armorClass!
        XCTAssertEqual(session.combatants[0].effectiveArmorClass, base)
        session.grantTemporaryAC(to: wren, amount: 2)
        XCTAssertEqual(session.combatants[0].effectiveArmorClass, base + 2)
        XCTAssertEqual(session.combatants[0].armorClass, base)
    }

    func testNoArmorClassMeansNoneInPlay() {
        var combatant = Combatant(name: "Wren", initiative: 12)
        combatant.temporaryAC = 2
        XCTAssertNil(combatant.effectiveArmorClass)
    }

    func testTemporaryACCanBeRemoved() {
        let session = TestCombats.wrenWithArmorClass()
        let wren = session.combatants[0].id
        session.grantTemporaryAC(to: wren, amount: 2)
        session.removeTemporaryAC(from: wren)
        XCTAssertNil(session.combatants[0].temporaryAC)
        XCTAssertEqual(session.log.last?.text, "Wren lost temporary AC")
    }
}
