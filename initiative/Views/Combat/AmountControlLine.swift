import SwiftUI

/// One stat on one line: label, the value, its change since the turn started, then
/// a decrease button, a number box for the amount and an increase button. When
/// `set` is given, the value is a button that asks for an exact number. The
/// Health card (current, temporary and max HP) and the Armor Class card (AC and
/// temporary AC) are built from it, so every line reads and works the same.
struct AmountControlLine: View {
    let label: String
    let value: Int
    var change: Int? = nil
    let decreaseLabel: String
    let increaseLabel: String
    let decrease: (Int) -> Void
    let increase: (Int) -> Void
    /// Sets an exact value; nil where only − and + make sense.
    var set: ((Int) -> Void)? = nil

    @State private var amount = "1"
    @State private var settingValue = false
    @State private var typedValue = ""

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ColumnLabel(label)
            if set != nil {
                Button {
                    typedValue = "\(value)"
                    settingValue = true
                } label: {
                    Text("\(value)")
                        .font(Theme.Typography.statLarge)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xxs)
                        .background(Theme.surfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(label) \(value), set exactly")
            } else {
                Text("\(value)")
                    .font(Theme.Typography.statLarge)
            }
            if let change {
                ChangeLabel(change: change)
                    .font(Theme.Typography.bodyEmphasis)
            }
            Spacer(minLength: Theme.Spacing.xs)
            ControlButton(systemImage: "minus", tint: Theme.statusBad, label: decreaseLabel) {
                decrease(Self.amount(from: amount))
            }
            // Selects its number when tapped, so a new amount types straight over it.
            SelectAllTextField(
                text: $amount,
                placeholder: "1",
                font: .preferredFont(forTextStyle: .subheadline).semibold,
                keyboardType: .numberPad
            )
                .frame(width: 48, height: 38)
                .background(Theme.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
            ControlButton(systemImage: "plus", tint: Theme.statusGood, label: increaseLabel) {
                increase(Self.amount(from: amount))
            }
        }
        .alert("Set \(label)", isPresented: $settingValue) {
            TextField("\(value)", text: $typedValue)
                .keyboardType(.numberPad)
            Button("Set") {
                if let typed = Int(typedValue), typed >= 0 { set?(typed) }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    /// The number in the box, at least 1.
    private static func amount(from text: String) -> Int {
        max(1, Int(text) ?? 1)
    }
}

#Preview {
    AmountControlLine(label: "Armor Class", value: 14, change: 1, decreaseLabel: "Lower", increaseLabel: "Raise", decrease: { _ in }, increase: { _ in })
        .padding()
}
