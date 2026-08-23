import SwiftUI

/// A full set of colors for one look. `Theme` below always reflects whichever
/// palette is currently selected in `ThemeManager`.
struct ThemePalette: Identifiable, CaseIterable {
    let id: String
    let displayName: String
    let background: Color
    let accent: Color
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let divider: Color

    static let original = ThemePalette(
        id: "original", displayName: "Rust & Paper (original)",
        background: Color(red: 0.96, green: 0.94, blue: 0.93),
        accent: Color(red: 0.78, green: 0.14, blue: 0.11),
        textPrimary: Color(red: 0.17, green: 0.15, blue: 0.13),
        textSecondary: Color(red: 0.43, green: 0.35, blue: 0.32),
        textTertiary: Color(red: 0.60, green: 0.50, blue: 0.45),
        divider: Color(red: 0.83, green: 0.76, blue: 0.72)
    )

    static let inkAndParchment = ThemePalette(
        id: "inkAndParchment", displayName: "Ink & Parchment",
        background: Color(red: 0.95, green: 0.91, blue: 0.84),
        accent: Color(red: 0.18, green: 0.26, blue: 0.45),
        textPrimary: Color(red: 0.12, green: 0.10, blue: 0.08),
        textSecondary: Color(red: 0.35, green: 0.30, blue: 0.24),
        textTertiary: Color(red: 0.55, green: 0.48, blue: 0.40),
        divider: Color(red: 0.82, green: 0.74, blue: 0.62)
    )

    static let dungeonStone = ThemePalette(
        id: "dungeonStone", displayName: "Dungeon Stone",
        background: Color(red: 0.89, green: 0.89, blue: 0.89),
        accent: Color(red: 0.12, green: 0.36, blue: 0.24),
        textPrimary: Color(red: 0.15, green: 0.16, blue: 0.16),
        textSecondary: Color(red: 0.35, green: 0.37, blue: 0.37),
        textTertiary: Color(red: 0.55, green: 0.57, blue: 0.57),
        divider: Color(red: 0.75, green: 0.76, blue: 0.76)
    )

    static let tavernCandlelight = ThemePalette(
        id: "tavernCandlelight", displayName: "Tavern Candlelight",
        background: Color(red: 0.23, green: 0.16, blue: 0.13),
        accent: Color(red: 0.85, green: 0.64, blue: 0.25),
        textPrimary: Color(red: 0.94, green: 0.90, blue: 0.85),
        textSecondary: Color(red: 0.78, green: 0.70, blue: 0.60),
        textTertiary: Color(red: 0.60, green: 0.52, blue: 0.44),
        divider: Color(red: 0.40, green: 0.30, blue: 0.24)
    )

    static let oldMap = ThemePalette(
        id: "oldMap", displayName: "Old Map",
        background: Color(red: 0.91, green: 0.86, blue: 0.76),
        accent: Color(red: 0.55, green: 0.23, blue: 0.23),
        textPrimary: Color(red: 0.29, green: 0.22, blue: 0.16),
        textSecondary: Color(red: 0.45, green: 0.37, blue: 0.28),
        textTertiary: Color(red: 0.60, green: 0.52, blue: 0.42),
        divider: Color(red: 0.78, green: 0.70, blue: 0.56)
    )

    static let allCases: [ThemePalette] = [.original, .inkAndParchment, .dungeonStone, .tavernCandlelight, .oldMap]
}

/// TEMPORARY: lets the theme be switched live from a menu button for side-by-side
/// palette comparison. Remove `ThemeManager`/`ThemePicker` and hardcode back to a
/// single chosen palette in `Theme` once a palette is picked.
@Observable
class ThemeManager {
    static let shared = ThemeManager()
    var palette: ThemePalette = .original
}

/// Shared color palette used across all views — always reflects whichever
/// `ThemePalette` is currently selected via `ThemeManager.shared`.
enum Theme {
    static var background: Color { ThemeManager.shared.palette.background }
    static var accent: Color { ThemeManager.shared.palette.accent }
    static var textPrimary: Color { ThemeManager.shared.palette.textPrimary }
    static var textSecondary: Color { ThemeManager.shared.palette.textSecondary }
    static var textTertiary: Color { ThemeManager.shared.palette.textTertiary }
    static var divider: Color { ThemeManager.shared.palette.divider }
}

/// TEMPORARY: a menu button for switching palettes live to compare them. Drop this
/// view (and its call site) once a final palette is chosen.
struct ThemePicker: View {
    var body: some View {
        Menu {
            ForEach(ThemePalette.allCases) { palette in
                Button(palette.displayName) {
                    ThemeManager.shared.palette = palette
                }
            }
        } label: {
            Image(systemName: "paintpalette.fill")
        }
        .accessibilityLabel("Switch Theme (temporary)")
    }
}

/// Generic approximate-status bands shown in player view (DM's screen visible to
/// players) instead of exact numbers — deliberately generic wording, not
/// tabletop RPG-specific terms like "Bloodied". Shared by the combatant list and detail
/// screen so both read the same bands.
enum StatusBand {
    static func health(current: Int, max: Int) -> (label: String, color: Color) {
        if current <= 0 { return ("Dead", .black) }
        let fraction = Double(current) / Double(max)
        if fraction > 0.5 { return ("Healthy", .green) }
        if fraction > 0.25 { return ("Wounded", .orange) }
        return ("Critical", .red)
    }

    static func armorClass(_ ac: Int) -> (label: String, color: Color) {
        if ac >= 17 { return ("High AC", .blue) }
        if ac >= 13 { return ("Average AC", .orange) }
        return ("Low AC", .red)
    }
}

/// A left-to-right layout that wraps to the next line on overflow, like a row of
/// tag/chip UI elements — unlike HStack, which never wraps and just overflows.
struct FlowLayout: Layout {
    var horizontalSpacing: CGFloat = 6
    var verticalSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var totalWidth: CGFloat = 0
        var totalHeight: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + verticalSpacing
                totalWidth = max(totalWidth, rowWidth)
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + (rowWidth > 0 ? horizontalSpacing : 0)
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        totalWidth = max(totalWidth, rowWidth)
        return CGSize(width: totalWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + verticalSpacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + horizontalSpacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
