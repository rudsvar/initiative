import XCTest
@testable import initiative

/// A new session is named after when it started, written the way the phone's
/// region writes dates and times.
final class SessionNameTests: XCTestCase {
    private let date = DateComponents(
        calendar: Calendar(identifier: .gregorian), timeZone: TimeZone(identifier: "UTC"),
        year: 2026, month: 11, day: 17, hour: 22, minute: 20
    ).date!

    private func name(_ identifier: String) -> String {
        CombatSession.defaultName(at: date, locale: Locale(identifier: identifier), timeZone: TimeZone(identifier: "UTC")!)
    }

    func testTheNameFollowsTheRegion() {
        XCTAssertEqual(name("en_US"), "11/17/26, 10:20\u{202F}PM")
        XCTAssertEqual(name("en_GB"), "17/11/2026, 22:20")
        XCTAssertEqual(name("nb_NO"), "17.11.2026, 22:20")
    }
}
