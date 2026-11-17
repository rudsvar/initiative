import XCTest
@testable import initiative

/// The effect editor reads a duration into its form and writes it back on Save.
/// Saving without changing anything must give back the same duration.
final class EffectTimingTests: XCTestCase {

    func testEveryCombatantDurationSurvivesARoundTrip() {
        let durations: [DurationType] = [
            .untilStartOfTheirTurn(remainingTurns: 3),
            .untilEndOfTheirTurn(remainingTurns: 1),
            .untilRollSucceeds(at: .endOfTurn, hint: "DC 14 Con"),
            .untilRollSucceeds(at: .startOfTurn, hint: nil),
            .untilRemoved,
        ]
        for duration in durations {
            XCTAssertEqual(EffectTiming(duration).durationType, duration, "\(duration)")
        }
    }

    func testANewEffectStartsAsASaveAtTheStartOfTheTurn() {
        XCTAssertEqual(EffectTiming(nil).durationType, .untilRollSucceeds(at: .startOfTurn, hint: nil))
    }
}
