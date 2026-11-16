import SwiftUI

/// A creature or character as one list row: its name, then HP, AC and initiative
/// bonus. Shared by the library screens so they read the same.
///
/// The stats line up down the list without a hardcoded width: each row reports how
/// wide its own values are, the list (`sharedStatColumns()`) keeps the widest per
/// column, and every row sizes to that. Larger text or a three-digit HP widens the
/// column on its own, and the name keeps whatever is left.
struct PresetRowLabel: View {
    let preset: CreaturePreset
    @Environment(\.statColumnWidths) private var widths

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(preset.name)
                    .font(Theme.Typography.rowTitle)
                    .foregroundColor(Theme.textPrimary)
                if let rating = preset.effectiveChallengeRating {
                    Text("CR \(rating) · \(preset.effectiveXP.map(String.init) ?? "–") XP")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.textTertiary)
                }
            }
            Spacer(minLength: Theme.Spacing.sm)
            HStack(spacing: Theme.Spacing.sm) {
                column("heart.fill", preset.maxHP.map(String.init), color: Theme.statusBad, width: widths.hp) { $0.hp = $1 }
                column("shield.fill", preset.armorClass.map(String.init), color: Theme.statusInfo, width: widths.ac) { $0.ac = $1 }
                column("die.face.5.fill", preset.initiativeBonus.map { $0 >= 0 ? "+\($0)" : "\($0)" }, color: Theme.textSecondary, width: widths.bonus) { $0.bonus = $1 }
            }
        }
    }

    /// A missing stat keeps its column, shown as a dash.
    private func column(
        _ systemImage: String,
        _ value: String?,
        color: Color,
        width: CGFloat,
        report: @escaping (inout StatColumnWidths, CGFloat) -> Void
    ) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: systemImage)
                .font(Theme.Typography.iconInline)
            Text(value ?? "–")
        }
        .font(Theme.Typography.stat)
        .foregroundColor(value == nil ? Theme.textTertiary : color)
        .fixedSize()
        .background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: StatColumnWidthsKey.self,
                    value: {
                        var widths = StatColumnWidths()
                        report(&widths, proxy.size.width)
                        return widths
                    }()
                )
            }
        )
        .frame(minWidth: width, alignment: .trailing)
    }
}

/// The widest value seen so far in each stat column.
struct StatColumnWidths: Equatable {
    var hp: CGFloat = 0
    var ac: CGFloat = 0
    var bonus: CGFloat = 0
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
    /// Put on the list holding `PresetRowLabel` rows so their stats share columns.
    func sharedStatColumns() -> some View {
        modifier(SharedStatColumns())
    }
}
