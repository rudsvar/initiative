import SwiftUI

/// A change in a value, as an arrow and an unsigned number: a red down arrow for a
/// fall, a green up arrow for a rise. The number is bold in the same colour. No
/// minus sign, so "7 ↓3" can't be read as a subtraction the wrong way round.
struct ChangeLabel: View {
    let change: Int

    private var falling: Bool { change < 0 }

    var body: some View {
        HStack(spacing: 1) {
            Image(systemName: falling ? "arrow.down" : "arrow.up")
            Text("\(abs(change))")
        }
        .fontWeight(.bold)
        .foregroundColor(falling ? Theme.statusBad : Theme.statusGood)
    }
}

#Preview {
    VStack(alignment: .leading) {
        ChangeLabel(change: -3)
        ChangeLabel(change: 5)
    }
}
