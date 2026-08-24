import XCTest
import SwiftUI
@testable import initiative

final class ConditionLibraryTests: XCTestCase {

    func testMatchingFindsExactName() {
        XCTAssertEqual(ConditionLibrary.matching(name: "Stunned")?.name, "Stunned")
    }

    /// Effects store only a free-text name, and that name can come from the user
    /// typing it rather than picking from the list — so lookup has to be
    /// case-insensitive or a hand-typed "stunned" would lose its icon and color.
    func testMatchingIsCaseInsensitive() {
        XCTAssertEqual(ConditionLibrary.matching(name: "stunned")?.name, "Stunned")
        XCTAssertEqual(ConditionLibrary.matching(name: "POISONED")?.name, "Poisoned")
    }

    func testMatchingReturnsNilForCustomEffectName() {
        XCTAssertNil(ConditionLibrary.matching(name: "Hexed by the Duke"))
    }

    /// Whitespace is *not* trimmed here — callers pass already-trimmed names
    /// (see AddEffectView.addEffect). Pinned so a future "helpful" trim inside
    /// the lookup is a deliberate change rather than an accident.
    func testMatchingDoesNotTrimWhitespace() {
        XCTAssertNil(ConditionLibrary.matching(name: " Stunned "))
    }

    func testNamesAreUnique() {
        let names = ConditionLibrary.all.map { $0.name.lowercased() }
        XCTAssertEqual(Set(names).count, names.count, "Two conditions share a name; matching(name:) would be ambiguous")
    }

    func testEverySymbolIsDistinct() {
        // A repeated glyph in the initiative list makes two different conditions
        // indistinguishable at a glance, which is the one thing the chips exist for.
        let symbols = ConditionLibrary.all.map { $0.symbolName }
        XCTAssertEqual(Set(symbols).count, symbols.count, "Two conditions share an SF Symbol")
    }

    /// Candle gold is reserved for the current-turn marker (see `Theme`). A
    /// condition tinted the same color would compete with it in the combatant
    /// list, which is exactly the problem the category palette was introduced to
    /// solve — so no category may drift back toward the accent.
    func testNoCategoryColorCollidesWithTheAccent() {
        let accent = Theme.accent.rgbComponents
        let categories: [ConditionCategory] = [.sensory, .mental, .restraint, .disabling, .ongoing]
        for category in categories {
            let color = category.color.rgbComponents
            let distance = abs(color.r - accent.r) + abs(color.g - accent.g) + abs(color.b - accent.b)
            XCTAssertGreaterThan(
                distance, 0.3,
                "\(category) is too close to Theme.accent and will compete with the current-turn marker"
            )
        }
    }

    func testEveryConditionResolvesToItsCategoryColor() {
        for condition in ConditionLibrary.all {
            XCTAssertEqual(
                condition.color.rgbComponents.r,
                condition.category.color.rgbComponents.r,
                accuracy: 0.0001,
                "\(condition.name) does not take its color from its category"
            )
        }
    }
}

private extension Color {
    /// Enough of a color to compare in tests. `Color` isn't directly decomposable,
    /// so this goes through UIColor.
    var rgbComponents: (r: CGFloat, g: CGFloat, b: CGFloat) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (r, g, b)
    }
}
