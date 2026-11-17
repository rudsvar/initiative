import XCTest
import SwiftUI
@testable import initiative

/// An effect's icon and colour come from one rule, used by the roster chip, the
/// effect row and the cooldown chip alike.
final class EffectAppearanceTests: XCTestCase {

    func testEachKindOfEffectHasItsIcon() {
        var dying = Effect(name: "Dying", durationType: .untilRemoved)
        dying.deathSaves = DeathSaves()
        XCTAssertEqual(dying.symbolName, "heart.slash.fill")
        XCTAssertEqual(Effect(name: "Recharging", durationType: .untilRollSucceeds(at: .startOfTurn, hint: nil), kind: .cooldown).symbolName, "hourglass")
        XCTAssertEqual(Effect(name: "Once", durationType: .untilRemoved, kind: .cooldown).symbolName, "clock")
        XCTAssertEqual(Effect(name: "prone", durationType: .untilRemoved).symbolName, ConditionLibrary.matching(name: "Prone")!.symbolName)
        XCTAssertEqual(Effect(name: "Hexed", durationType: .untilRemoved).symbolName, "sparkles")
    }

    /// The accent marks the current turn and nothing else on the roster.
    func testNoEffectIsAccentColoured() {
        let effects = [
            Effect(name: "Hexed", durationType: .untilRemoved),
            Effect(name: "Recharging", durationType: .untilRemoved, kind: .cooldown),
            Effect(name: "Prone", durationType: .untilRemoved),
        ]
        for effect in effects {
            XCTAssertNotEqual(effect.tint, Theme.accent, effect.name)
        }
    }
}
