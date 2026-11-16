import SwiftUI

/// A creature or character as one list row: its name, then HP, AC and initiative
/// bonus in fixed columns. Shared by the library and the picker that starts a new
/// entry, so the two read the same.
struct PresetRowLabel: View {
    let preset: CreaturePreset

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Text(preset.name)
                .font(Theme.Typography.rowTitle)
                .foregroundColor(Theme.textPrimary)
            Spacer(minLength: Theme.Spacing.sm)
            // Fixed-width columns so each stat lines up down the list.
            // A missing stat keeps its column, shown as a dash.
            HStack(spacing: Theme.Spacing.md) {
                statColumn("heart.fill", preset.maxHP.map(String.init), color: Theme.statusBad)
                statColumn("shield.fill", preset.armorClass.map(String.init), color: Theme.statusInfo)
                statColumn("die.face.5.fill", preset.initiativeBonus.map { $0 >= 0 ? "+\($0)" : "\($0)" }, color: Theme.textSecondary)
            }
        }
    }

    private func statColumn(_ systemImage: String, _ value: String?, color: Color) -> some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: systemImage)
                .font(Theme.Typography.iconInline)
                .frame(width: 12)
            Text(value ?? "–")
        }
        .font(Theme.Typography.stat)
        .foregroundColor(value == nil ? Theme.textTertiary : color)
        .frame(width: Theme.Layout.statColumn, alignment: .trailing)
    }
}
