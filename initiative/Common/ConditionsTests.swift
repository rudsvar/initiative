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

    /// The "no category may sit near the accent" rule now lives in
    /// `ThemePaletteTests`, which checks it against every palette rather than
    /// only whichever one is selected.

    /// Categories must resolve through the live theme, so that switching palettes
    /// actually recolors the chips instead of leaving one hue hardcoded behind.
    func testEveryCategoryResolvesThroughTheSelectedPalette() {
        let palette = Theme.palette
        let expected: [(ConditionCategory, Color)] = [
            (.sensory, palette.conditionSensory),
            (.mental, palette.conditionMental),
            (.restraint, palette.conditionRestraint),
            (.disabling, palette.conditionDisabling),
            (.ongoing, palette.conditionOngoing),
        ]
        for (category, color) in expected {
            XCTAssertEqual(category.color.distance(to: color), 0, accuracy: 0.0001,
                           "\(category) does not read its color from the palette")
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

extension ConditionLibraryTests {

    /// The research finding, pinned: six of the sixteen conditions are ended by
    /// doing something about them rather than by a countdown or a boundary roll,
    /// so `untilRemoved` is not an edge case and these must not drift back to a
    /// timer.
    func testConditionsCounteredByActionDefaultToUntilRemoved() {
        for name in ["Prone", "Grappled", "Unconscious", "Burning", "Exhausted", "Invisible"] {
            XCTAssertEqual(
                ConditionLibrary.matching(name: name)?.defaultDuration, .untilRemoved,
                "\(name) ends when someone does something about it, not on a schedule"
            )
        }
    }

    func testConditionsThatUsuallyAllowASaveDefaultToARoll() {
        for name in ["Frightened", "Charmed", "Paralyzed", "Stunned", "Restrained", "Poisoned"] {
            XCTAssertTrue(
                ConditionLibrary.matching(name: name)?.defaultDuration.awaitsRoll == true,
                "\(name) is commonly save-ends and should prefill that way"
            )
        }
    }

    func testEveryConditionHasADefaultDuration() {
        // Nothing to assert beyond it compiling and being reachable, but this
        // fails loudly if a condition is added without one being considered.
        XCTAssertEqual(ConditionLibrary.all.count, 17)
    }
}
