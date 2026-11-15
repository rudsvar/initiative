import SwiftUI

/// The death-save tally next to a dying combatant's name: a row of three checkmark
/// circles for successes and a row of three cross circles for failures. Each one fills
/// as its result is recorded.
struct DeathSaveDots: View {
    let saves: DeathSaves

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            dots(filled: saves.successes, symbol: "checkmark", tint: Theme.statusGood)
            dots(filled: saves.failures, symbol: "xmark", tint: Theme.statusBad)
        }
        .accessibilityLabel("Successes \(saves.successes) of \(DeathSaves.required), failures \(saves.failures) of \(DeathSaves.required)")
    }

    private func dots(filled: Int, symbol: String, tint: Color) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<DeathSaves.required, id: \.self) { index in
                Image(systemName: index < filled ? "\(symbol).circle.fill" : "circle")
                    .font(Theme.Typography.label)
                    .foregroundColor(index < filled ? tint : Theme.textTertiary)
            }
        }
    }
}
