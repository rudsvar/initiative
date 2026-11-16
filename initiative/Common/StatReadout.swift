import SwiftUI

/// Which column of readouts a `StatReadout` belongs to, so that the same stat lines
/// up down a list.
enum StatColumn {
    case hp, ac, bonus
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
    @Environment(\.statColumnWidths) private var widths

    var body: some View {
        VStack(spacing: Theme.Spacing.xxs) {
            Image(systemName: systemImage)
                .font(Theme.Typography.readoutIcon)
                .foregroundColor(iconColor)
            value()
                .font(Theme.Typography.readout)
        }
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
    var hp: CGFloat = 0
    var ac: CGFloat = 0
    var bonus: CGFloat = 0

    init() {}

    init(reporting width: CGFloat, for column: StatColumn) {
        switch column {
        case .hp: hp = width
        case .ac: ac = width
        case .bonus: bonus = width
        }
    }

    func width(of column: StatColumn) -> CGFloat {
        switch column {
        case .hp: hp
        case .ac: ac
        case .bonus: bonus
        }
    }
}

private struct StatColumnWidthsKey: PreferenceKey {
    static let defaultValue = StatColumnWidths()
    static func reduce(value: inout StatColumnWidths, nextValue: () -> StatColumnWidths) {
        let next = nextValue()
        value.hp = max(value.hp, next.hp)
        value.ac = max(value.ac, next.ac)
        value.bonus = max(value.bonus, next.bonus)
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
}
