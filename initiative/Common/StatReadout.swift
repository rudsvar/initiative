import SwiftUI

/// Which column of readouts a `StatReadout` belongs to, so that the same stat lines
/// up down a list. `menuIcon` is the main menu's icon column, measured the same way
/// so a wide symbol widens the column instead of sticking out of it.
enum StatColumn {
    case initiative, hp, ac, bonus, menuIcon
}

/// One stat as a small stack: its symbol above its value. Used for HP, AC and
/// initiative bonus everywhere they appear (library rows, encounter rows, the
/// combat roster), so they share one size and one look.
///
/// Columns line up without a hardcoded width: each readout reports how wide it is,
/// the list (`sharedStatColumns()`) keeps the widest per column, and every readout
/// sizes to that. Larger text or a three-digit HP widens the column on its own, and
/// the name keeps whatever is left.
struct StatReadout<Value: View>: View {
    let systemImage: String
    let iconColor: Color
    let column: StatColumn
    @ViewBuilder let value: () -> Value

    var body: some View {
        VStack(spacing: Theme.Spacing.xxs) {
            Image(systemName: systemImage)
                .font(Theme.Typography.readoutIcon)
                .foregroundColor(iconColor)
            value()
                .font(Theme.Typography.readout)
        }
        .statColumn(column)
    }
}

/// Reports this view's width for `column` and widens it to the column's widest.
private struct StatColumnMember: ViewModifier {
    let column: StatColumn
    @Environment(\.statColumnWidths) private var widths

    func body(content: Content) -> some View {
        content
            .fixedSize()
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: StatColumnWidthsKey.self,
                        value: StatColumnWidths(reporting: proxy.size.width, for: column)
                    )
                }
            )
            .frame(minWidth: widths.width(of: column))
    }
}

/// The widest value seen so far in each stat column.
struct StatColumnWidths: Equatable {
    var initiative: CGFloat = 0
    var hp: CGFloat = 0
    var ac: CGFloat = 0
    var bonus: CGFloat = 0
    var menuIcon: CGFloat = 0

    init() {}

    init(reporting width: CGFloat, for column: StatColumn) {
        switch column {
        case .initiative: initiative = width
        case .hp: hp = width
        case .ac: ac = width
        case .bonus: bonus = width
        case .menuIcon: menuIcon = width
        }
    }

    func width(of column: StatColumn) -> CGFloat {
        switch column {
        case .initiative: initiative
        case .hp: hp
        case .ac: ac
        case .bonus: bonus
        case .menuIcon: menuIcon
        }
    }
}

private struct StatColumnWidthsKey: PreferenceKey {
    static let defaultValue = StatColumnWidths()
    static func reduce(value: inout StatColumnWidths, nextValue: () -> StatColumnWidths) {
        let next = nextValue()
        value.initiative = max(value.initiative, next.initiative)
        value.hp = max(value.hp, next.hp)
        value.ac = max(value.ac, next.ac)
        value.bonus = max(value.bonus, next.bonus)
        value.menuIcon = max(value.menuIcon, next.menuIcon)
    }
}

private struct StatColumnWidthsEnvironmentKey: EnvironmentKey {
    static let defaultValue = StatColumnWidths()
}

extension EnvironmentValues {
    fileprivate(set) var statColumnWidths: StatColumnWidths {
        get { self[StatColumnWidthsEnvironmentKey.self] }
        set { self[StatColumnWidthsEnvironmentKey.self] = newValue }
    }
}

private struct SharedStatColumns: ViewModifier {
    @State private var widths = StatColumnWidths()

    func body(content: Content) -> some View {
        content
            .environment(\.statColumnWidths, widths)
            .onPreferenceChange(StatColumnWidthsKey.self) { widths = $0 }
    }
}

extension View {
    /// Put on the list holding `StatReadout`s so each stat shares a column.
    func sharedStatColumns() -> some View {
        modifier(SharedStatColumns())
    }

    /// Makes this view one cell of a stat column (`sharedStatColumns()` on the list).
    func statColumn(_ column: StatColumn) -> some View {
        modifier(StatColumnMember(column: column))
    }
}
