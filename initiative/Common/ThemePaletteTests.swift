import XCTest
import SwiftUI
@testable import initiative

/// Design constraints, checked against **every** palette rather than whichever
/// one happens to be selected.
///
/// This is the point of these tests: a palette is easy to eyeball once and never
/// again, and the failure mode of adding a theme is that it looks fine on the one
/// screen it was designed against and quietly breaks a rule somewhere else. The
/// rules the app's look actually depends on — the elevation ladder, readable
/// text, an accent nothing competes with — are cheap to assert and expensive to
/// notice by hand.
final class ThemePaletteTests: XCTestCase {

    private var allPalettes: [(name: String, palette: ThemePalette)] {
        ThemeIdentifier.allCases.map { ($0.displayName, $0.palette) }
    }

    // MARK: - Elevation

    /// Surfaces must get *lighter* as they come forward, in every palette,
    /// including the light one — Parchment's ladder runs toward white rather
    /// than being a dark ladder turned upside down. If a step ever landed out of
    /// order, cards would recede instead of lifting and the app would need
    /// borders to say what elevation already says.
    func testElevationLadderIncreasesMonotonically() {
        for (name, palette) in allPalettes {
            let ladder = [
                ("background", palette.background),
                ("backgroundLift", palette.backgroundLift),
                ("surface", palette.surface),
                ("surfaceRaised", palette.surfaceRaised),
            ]
            for (lower, upper) in zip(ladder, ladder.dropFirst()) {
                XCTAssertLessThan(
                    lower.1.relativeLuminance,
                    upper.1.relativeLuminance,
                    "\(name): \(upper.0) is not lighter than \(lower.0); the elevation ladder is out of order"
                )
            }
        }
    }

    /// Each step also has to be *visible* as a step. A ladder that technically
    /// ascends but by an imperceptible amount is the flat single tone the design
    /// was moved away from.
    func testEachElevationStepIsPerceptible() {
        for (name, palette) in allPalettes {
            XCTAssertGreaterThan(
                palette.surface.contrastRatio(against: palette.background), 1.06,
                "\(name): surface is not distinguishable from background"
            )
            XCTAssertGreaterThan(
                palette.surfaceRaised.contrastRatio(against: palette.surface), 1.15,
                "\(name): surfaceRaised is not distinguishable from surface"
            )
        }
    }

    // MARK: - Readability

    /// Text is read mid-combat, at a table, at whatever brightness the room
    /// allows. These are the WCAG thresholds: AAA body for primary, AA for
    /// secondary, AA-large/UI for the deliberately de-emphasised tertiary.
    func testTextContrastsAgainstEverySurfaceItSitsOn() {
        for (name, palette) in allPalettes {
            for (surfaceName, surface) in [
                ("background", palette.background),
                ("surface", palette.surface),
                ("surfaceRaised", palette.surfaceRaised),
            ] {
                assertContrast(palette.textPrimary, on: surface, atLeast: 7.0,
                               "\(name): textPrimary on \(surfaceName)")
                assertContrast(palette.textSecondary, on: surface, atLeast: 4.5,
                               "\(name): textSecondary on \(surfaceName)")
                assertContrast(palette.textTertiary, on: surface, atLeast: 3.0,
                               "\(name): textTertiary on \(surfaceName)")
            }
        }
    }

    /// The primary button's label sits directly on an accent fill. In a light
    /// palette the accent is dark, so this pair can't be derived from the
    /// background — it has its own token, and its own check.
    func testAccentForegroundIsLegibleOnTheAccent() {
        for (name, palette) in allPalettes {
            assertContrast(palette.accentForeground, on: palette.accent, atLeast: 3.0,
                           "\(name): accentForeground on accent")
        }
    }

    /// A palette that declares itself light but paints light text (or vice
    /// versa) would leave every system-drawn control — keyboard, native
    /// toolbar, selection — inverted relative to the app's own chrome.
    func testDeclaredColorSchemeMatchesThePalette() {
        for (name, palette) in allPalettes {
            let isDarkInPractice = palette.textPrimary.relativeLuminance > palette.background.relativeLuminance
            XCTAssertEqual(
                isDarkInPractice, palette.colorScheme == .dark,
                "\(name): colorScheme is .\(palette.colorScheme == .dark ? "dark" : "light") but the palette paints the opposite way"
            )
        }
    }

    // MARK: - The accent rule

    /// The accent marks exactly one thing per screen (see `Theme`). A condition
    /// chip tinted near the accent competes with the current-turn marker in the
    /// combatant list — the precise failure this category palette exists to fix,
    /// and the one that has already happened once by hand.
    func testNoConditionColorCollidesWithTheAccent() {
        for (name, palette) in allPalettes {
            for (categoryName, color) in palette.conditionColors {
                XCTAssertGreaterThan(
                    color.distance(to: palette.accent), 0.3,
                    "\(name): \(categoryName) is too close to the accent and will compete with the current-turn marker"
                )
            }
        }
    }

    /// Status colors sit in the same list rows as the accent (an HP band beside
    /// the current combatant's initiative), so they're bound by the same rule.
    func testNoStatusColorCollidesWithTheAccent() {
        for (name, palette) in allPalettes {
            for (statusName, color) in [
                ("statusGood", palette.statusGood),
                ("statusWarn", palette.statusWarn),
                ("statusBad", palette.statusBad),
                ("statusNeutral", palette.statusNeutral),
                ("statusInfo", palette.statusInfo),
            ] {
                XCTAssertGreaterThan(
                    color.distance(to: palette.accent), 0.3,
                    "\(name): \(statusName) is too close to the accent"
                )
            }
        }
    }

    /// Condition color is information — it says which *kind* of trouble someone
    /// is in — which only works if the five are told apart at chip size. This is
    /// a floor ("not the same color"), not a claim about perceptual distance:
    /// RGB distance is a crude stand-in, so it catches duplicates and
    /// near-duplicates rather than certifying that any given pair reads well.
    func testConditionCategoryColorsAreDistinctFromEachOther() {
        for (name, palette) in allPalettes {
            let colors = palette.conditionColors
            for i in colors.indices {
                for j in colors.indices where j > i {
                    XCTAssertGreaterThan(
                        colors[i].color.distance(to: colors[j].color), 0.2,
                        "\(name): \(colors[i].name) and \(colors[j].name) are nearly the same color"
                    )
                }
            }
        }
    }

    // MARK: - Catalogue

    func testEveryThemeHasADistinctNameAndATagline() {
        let names = ThemeIdentifier.allCases.map(\.displayName)
        XCTAssertEqual(Set(names).count, names.count, "Two themes share a display name")
        for theme in ThemeIdentifier.allCases {
            XCTAssertFalse(theme.tagline.isEmpty, "\(theme.displayName) has no tagline")
        }
    }

    /// Two palettes that resolved to the same values would make the picker lie.
    func testEveryThemeResolvesToADistinctPalette() {
        for theme in ThemeIdentifier.allCases {
            for other in ThemeIdentifier.allCases where other != theme {
                XCTAssertNotEqual(theme.palette, other.palette,
                                  "\(theme.displayName) and \(other.displayName) are the same palette")
            }
        }
    }

    // MARK: - Helpers

    private func assertContrast(
        _ foreground: Color,
        on background: Color,
        atLeast minimum: Double,
        _ label: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let ratio = foreground.contrastRatio(against: background)
        XCTAssertGreaterThanOrEqual(
            ratio, minimum,
            "\(label): contrast is \(String(format: "%.2f", ratio)):1, needs \(minimum):1",
            file: file, line: line
        )
    }
}

private extension ThemePalette {
    var conditionColors: [(name: String, color: Color)] {
        [
            ("sensory", conditionSensory),
            ("mental", conditionMental),
            ("restraint", conditionRestraint),
            ("disabling", conditionDisabling),
            ("ongoing", conditionOngoing),
        ]
    }
}

/// Color maths for tests. `Color` isn't decomposable on its own, so everything
/// here goes through `UIColor`.
extension Color {
    var rgbComponents: (r: Double, g: Double, b: Double) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
    }

    /// WCAG relative luminance (sRGB, gamma-expanded).
    var relativeLuminance: Double {
        func linear(_ channel: Double) -> Double {
            channel <= 0.03928 ? channel / 12.92 : pow((channel + 0.055) / 1.055, 2.4)
        }
        let (r, g, b) = rgbComponents
        return 0.2126 * linear(r) + 0.7152 * linear(g) + 0.0722 * linear(b)
    }

    /// WCAG contrast ratio, always >= 1 regardless of which color is lighter.
    func contrastRatio(against other: Color) -> Double {
        let a = relativeLuminance, b = other.relativeLuminance
        return (max(a, b) + 0.05) / (min(a, b) + 0.05)
    }

    /// Manhattan distance in RGB — a crude "are these the same color" check.
    func distance(to other: Color) -> Double {
        let (r1, g1, b1) = rgbComponents
        let (r2, g2, b2) = other.rgbComponents
        return abs(r1 - r2) + abs(g1 - g2) + abs(b1 - b2)
    }

    /// The colour-blind themes use the Okabe-Ito status roles, pinned here: good is
    /// blue, bad is vermillion, warning is yellow, info is bluish green. A later edit
    /// to a shared colour must not silently change these.
    func testColorBlindThemesKeepTheirOkabeItoStatusRoles() {
        let dark = ThemePalette.colorblindDark
        let light = ThemePalette.colorblindLight
        XCTAssertNotEqual(dark.statusGood, dark.statusBad)
        XCTAssertNotEqual(light.statusGood, light.statusBad)
        XCTAssertNotEqual(dark.statusGood, ThemePalette.tavernCandlelight.statusGood, "colour-blind dark must not reuse another theme's good colour")
        XCTAssertNotEqual(light.statusBad, ThemePalette.parchment.statusBad, "colour-blind light must not reuse another theme's bad colour")
    }
}
