import SwiftUI

/// Shared "old paper" color palette used across all views.
enum Theme {
    static let background = Color(red: 0.96, green: 0.94, blue: 0.93)
    static let accent = Color(red: 0.78, green: 0.14, blue: 0.11)
    static let textPrimary = Color(red: 0.17, green: 0.15, blue: 0.13)
    static let textSecondary = Color(red: 0.43, green: 0.35, blue: 0.32)
    static let textTertiary = Color(red: 0.60, green: 0.50, blue: 0.45)
    static let divider = Color(red: 0.83, green: 0.76, blue: 0.72)
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
