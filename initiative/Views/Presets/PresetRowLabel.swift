import SwiftUI

/// A creature or character as one list row: its name, then HP, AC and initiative
/// bonus. Shared by the library screens so they read the same.
///
/// The stats are `StatReadout`s, which line up down the list on their own (see there).
struct PresetRowLabel: View {
    let preset: CreaturePreset
    /// More than one of it, as in an encounter's lineup: shown as "3× Goblin".
    var count = 1

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(count > 1 ? "\(count)× \(preset.name)" : preset.name)
                    .font(Theme.Typography.rowTitle)
                    .foregroundColor(Theme.textPrimary)
                if let challenge = preset.challenge {
                    Text("CR \(challenge.rating)\(challenge.isEstimate ? " (est.)" : "") · \(challenge.xp) XP")
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.textTertiary)
                }
            }
            Spacer(minLength: Theme.Spacing.sm)
            HStack(spacing: Theme.Spacing.sm) {
                readout("heart.fill", preset.maxHP.map(String.init), color: Theme.statusBad, column: .hp)
                readout("shield.fill", preset.armorClass.map(String.init), color: Theme.statusInfo, column: .ac)
                readout("die.face.5.fill", preset.initiativeBonus.map { $0 >= 0 ? "+\($0)" : "\($0)" }, color: Theme.textSecondary, column: .bonus)
            }
        }
    }

    /// A missing stat keeps its column, shown as a dash.
    private func readout(_ systemImage: String, _ value: String?, color: Color, column: StatColumn) -> some View {
        StatReadout(systemImage: systemImage, iconColor: color, column: column) {
            Text(value ?? "–")
                .foregroundColor(value == nil ? Theme.textTertiary : color)
        }
    }
}
