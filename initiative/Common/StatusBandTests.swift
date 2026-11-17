import XCTest
import SwiftUI
@testable import initiative

/// `StatusBand` is what players actually see when the DM turns on player view —
/// it's the only thing standing between "no information" and "the exact number" —
/// so the band boundaries are worth pinning down rather than assuming.
final class StatusBandTests: XCTestCase {

    // MARK: - Health

    func testFullHealthIsHealthy() {
        XCTAssertEqual(StatusBand.health(current: 20, max: 20).label, "Healthy")
    }

    func testJustOverHalfIsHealthy() {
        XCTAssertEqual(StatusBand.health(current: 11, max: 20).label, "Healthy")
    }

    /// Exactly half is *not* Healthy — the band is strictly greater than 50%.
    func testExactlyHalfIsWounded() {
        XCTAssertEqual(StatusBand.health(current: 10, max: 20).label, "Wounded")
    }

    func testJustOverQuarterIsWounded() {
        XCTAssertEqual(StatusBand.health(current: 6, max: 20).label, "Wounded")
    }

    /// Exactly a quarter is *not* Wounded — same strict-inequality reasoning.
    func testExactlyQuarterIsCritical() {
        XCTAssertEqual(StatusBand.health(current: 5, max: 20).label, "Critical")
    }

    func testOneHPIsCritical() {
        XCTAssertEqual(StatusBand.health(current: 1, max: 20).label, "Critical")
    }

    func testZeroHPIsDead() {
        XCTAssertEqual(StatusBand.health(current: 0, max: 20).label, "Dead")
    }

    /// Damage clamps at zero in `CombatSession`, but a hand-edited or migrated
    /// record could still carry a negative value; it must read as Dead, not fall
    /// through to a band computed from a negative fraction.
    func testNegativeHPIsDead() {
        XCTAssertEqual(StatusBand.health(current: -5, max: 20).label, "Dead")
    }

    /// A zero max would make the fraction a division by zero (NaN), and every
    /// `NaN > x` comparison is false — which would silently report a combatant at
    /// full health as "Critical". Guarded explicitly instead.
    func testZeroMaxWithRemainingHPIsNotCritical() {
        XCTAssertEqual(StatusBand.health(current: 5, max: 0).label, "Healthy")
    }

    func testDeadUsesNeutralColorNotBad() {
        // Dead is an end state, not an urgent one — it shouldn't read as the same
        // "act now" red as Critical.
        XCTAssertEqual(StatusBand.health(current: 0, max: 20).color, Theme.statusNeutral)
        XCTAssertEqual(StatusBand.health(current: 1, max: 20).color, Theme.statusBad)
    }

    // MARK: - Armor class

    func testArmorClassBands() {
        XCTAssertEqual(StatusBand.armorClass(20), "High AC")
        XCTAssertEqual(StatusBand.armorClass(17), "High AC")
        XCTAssertEqual(StatusBand.armorClass(16), "Medium AC")
        XCTAssertEqual(StatusBand.armorClass(13), "Medium AC")
        XCTAssertEqual(StatusBand.armorClass(12), "Low AC")
        XCTAssertEqual(StatusBand.armorClass(0), "Low AC")
    }

    /// No ruleset-specific or trademarked wording (e.g. "Bloodied") may leak into
    /// player-visible labels — see the project's no-copyrighted-material rule.
    func testBandLabelsAreGenericWording() {
        let labels = [
            StatusBand.health(current: 20, max: 20).label,
            StatusBand.health(current: 10, max: 20).label,
            StatusBand.health(current: 1, max: 20).label,
            StatusBand.health(current: 0, max: 20).label,
        ]
        XCTAssertEqual(labels, ["Healthy", "Wounded", "Critical", "Dead"])
    }
}
