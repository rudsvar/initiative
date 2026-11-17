import SwiftUI

/// Picks an amount with − and + and applies it in one of two directions. Used by
/// armor class: tap the number, choose how much, then choose the direction. The
/// sheet closes after either.
struct AdjustAmountSheet: View {
    let title: String
    let decreaseLabel: String
    let increaseLabel: String
    let onDecrease: (Int) -> Void
    let onIncrease: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var amount = 1

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Text(title).cardHeading()

            HStack(spacing: Theme.Spacing.lg) {
                stepButton("minus", label: "Less") { amount = max(1, amount - 1) }
                Text("\(amount)")
                    .font(Theme.Typography.numeric(44))
                    .foregroundColor(Theme.textPrimary)
                    .frame(minWidth: 90)
                stepButton("plus", label: "More") { amount = min(999, amount + 1) }
            }

            HStack(spacing: Theme.Spacing.sm) {
                Button {
                    onDecrease(amount)
                    dismiss()
                } label: {
                    Text(decreaseLabel)
                        .font(Theme.Typography.bodyEmphasis)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .tint(Theme.statusBad)

                Button {
                    onIncrease(amount)
                    dismiss()
                } label: {
                    Text(increaseLabel)
                        .font(Theme.Typography.bodyEmphasis)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .tint(Theme.statusGood)
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity)
        .presentationDetents([.height(260)])
        .presentationBackground(.regularMaterial)
    }

    private func stepButton(_ systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(Theme.Typography.iconAction)
                .frame(width: 52, height: 52)
                .background(Theme.surfaceRaised)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .foregroundColor(Theme.textPrimary)
        .accessibilityLabel(label)
    }
}

#Preview {
    AdjustAmountSheet(title: "Hit Points", decreaseLabel: "Damage", increaseLabel: "Heal", onDecrease: { _ in }, onIncrease: { _ in })
}
