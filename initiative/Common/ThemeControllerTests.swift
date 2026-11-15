import XCTest
@testable import initiative

/// Theme selection is a preference the user sets once and expects to stick, so
/// what's worth testing is the persistence edges rather than the colors: what
/// happens on a fresh install, across launches, and when the stored value is
/// something this build doesn't recognise.
///
/// Each test gets its own `UserDefaults` suite so nothing here can disturb the
/// real preference on a device the tests run against.
final class ThemeControllerTests: XCTestCase {

    private var suiteName = ""
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "ThemeControllerTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        super.tearDown()
    }

    func testFreshInstallUsesTheDefaultTheme() {
        let controller = ThemeController(defaults: defaults)
        XCTAssertEqual(controller.selection, ThemeController.defaultSelection)
        XCTAssertEqual(controller.palette, ThemeController.defaultSelection.palette)
    }

    func testSelectionSurvivesRelaunch() {
        let first = ThemeController(defaults: defaults)
        first.selection = .inkAndCinnabar

        let relaunched = ThemeController(defaults: defaults)
        XCTAssertEqual(relaunched.selection, .inkAndCinnabar)
    }

    func testPaletteFollowsSelection() {
        let controller = ThemeController(defaults: defaults)
        for theme in ThemeIdentifier.allCases {
            controller.selection = theme
            XCTAssertEqual(controller.palette, theme.palette, "\(theme.displayName) did not take effect")
        }
    }

    /// A theme removed in a later version leaves an unreadable value behind. That
    /// must degrade to the default, never to a crash or a blank screen — the
    /// preference is not important enough to be able to stop the app drawing.
    func testUnrecognisedStoredThemeFallsBackToTheDefault() {
        defaults.set("crimsonAndChrome", forKey: ThemeController.storageKey)

        let controller = ThemeController(defaults: defaults)
        XCTAssertEqual(controller.selection, ThemeController.defaultSelection)
    }

    /// Selecting the theme that's already active must not write or churn; the
    /// picker calls the setter on every tap, including on the current row.
    func testReselectingTheCurrentThemeIsANoOp() {
        let controller = ThemeController(defaults: defaults)
        controller.selection = .slateAndBrass
        controller.selection = .slateAndBrass

        XCTAssertEqual(controller.selection, .slateAndBrass)
        XCTAssertEqual(defaults.string(forKey: ThemeController.storageKey), ThemeIdentifier.slateAndBrass.rawValue)
    }

    /// Every theme in the enum is offered by the picker, which iterates
    /// `allCases` — so a theme added without a picker entry can't happen, but a
    /// theme whose raw value changed would silently orphan saved preferences.
    func testRawValuesArePinned() {
        XCTAssertEqual(
            ThemeIdentifier.allCases.map(\.rawValue),
            [
                "tavernCandlelight", "inkAndCinnabar", "slateAndBrass", "verdigris",
                "abyssal", "nightshade", "highContrast", "parchment", "vellum", "colorblindDark", "colorblindLight",
            ],
            "Renaming a case orphans every saved preference pointing at it"
        )
    }
}
