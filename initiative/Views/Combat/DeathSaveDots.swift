import SwiftUI

/// A dying combatant's mark, with the death-save tally beside it: a row of three
/// checkmark circles for successes and a row of three cross circles for failures, each
/// filled as its result is recorded. Sized to the height of the name.
struct DeathSaveDots: View {
    let saves: DeathSaves

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            // "skull.fill" is not an SF Symbol, so the dying mark uses the broken heart.
            Image(systemName: "heart.slash.fill")
                .font(Theme.Typography.skull)
                .foregroundColor(Theme.statusBad)
            VStack(alignment: .leading, spacing: 1) {
                dots(filled: saves.successes, symbol: "checkmark", tint: Theme.statusGood)
                dots(filled: saves.failures, symbol: "xmark", tint: Theme.statusBad)
            }
        }
        // Pinned to the name's line height, so a dying row is no taller than others.
        .frame(height: 22)
        .accessibilityLabel("Successes \(saves.successes) of \(DeathSaves.required), failures \(saves.failures) of \(DeathSaves.required)")
    }

    private func dots(filled: Int, symbol: String, tint: Color) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<DeathSaves.required, id: \.self) { index in
                Image(systemName: index < filled ? "\(symbol).circle.fill" : "circle")
                    .font(Theme.Typography.tally)
                    .foregroundColor(index < filled ? tint : Theme.textTertiary)
            }
        }
    }
}
