import SwiftUI

/// Shared color palette used across every screen — the single source of truth for
/// this app's look. **Tavern Candlelight**, chosen after comparing 5 live options
/// via a temporary in-app picker (now removed — see git history if palettes need
/// revisiting). Every screen must read colors from here rather than relying on
/// system defaults (`Form`/`List` are white by default and need an explicit
/// `Theme.background` + `.scrollContentBackground(.hidden)`, see e.g. ContentView).
enum Theme {
    static let background = Color(red: 0.23, green: 0.16, blue: 0.13)
    static let accent = Color(red: 0.85, green: 0.64, blue: 0.25)
    static let textPrimary = Color(red: 0.94, green: 0.90, blue: 0.85)
    static let textSecondary = Color(red: 0.78, green: 0.70, blue: 0.60)
    static let textTertiary = Color(red: 0.60, green: 0.52, blue: 0.44)
    static let divider = Color(red: 0.40, green: 0.30, blue: 0.24)

    // Semantic status colors (health/armor bands, etc.) — warm-toned to sit
    // comfortably against the dark brown background instead of clashing
    // primary red/green/blue, while still reading clearly as good/warn/bad.
    static let statusGood = Color(red: 0.56, green: 0.68, blue: 0.38)
    static let statusWarn = Color(red: 0.87, green: 0.58, blue: 0.24)
    static let statusBad = Color(red: 0.78, green: 0.32, blue: 0.26)
    static let statusNeutral = Color(red: 0.55, green: 0.50, blue: 0.46)
}

/// Generic approximate-status bands shown in player view (DM's screen visible to
/// players) instead of exact numbers — deliberately generic wording, not
/// tabletop RPG-specific terms like "Bloodied". Shared by the combatant list and detail
/// screen so both read the same bands.
enum StatusBand {
    static func health(current: Int, max: Int) -> (label: String, color: Color) {
        if current <= 0 { return ("Dead", Theme.statusNeutral) }
        let fraction = Double(current) / Double(max)
        if fraction > 0.5 { return ("Healthy", Theme.statusGood) }
        if fraction > 0.25 { return ("Wounded", Theme.statusWarn) }
        return ("Critical", Theme.statusBad)
    }

    /// Flavorful armor-coverage wording instead of raw "AC N" — reads like a
    /// DM's shorthand for "how hard is this to hit" rather than a bare stat.
    static func armorClass(_ ac: Int) -> (label: String, color: Color) {
        if ac >= 17 { return ("Heavily Armored", Theme.statusGood) }
        if ac >= 13 { return ("Lightly Armored", Theme.statusWarn) }
        return ("Unarmored", Theme.statusBad)
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
