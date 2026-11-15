import SwiftUI

/// A change in a value, shown as the bold number in red (down) or green (up). No
/// arrow and no sign: the colour carries the direction, and the number is the size.
struct ChangeLabel: View {
    let change: Int

    var body: some View {
        Text("\(abs(change))")
            .fontWeight(.bold)
            .foregroundColor(change < 0 ? Theme.statusBad : Theme.statusGood)
    }
}

#Preview {
    VStack(alignment: .leading) {
        ChangeLabel(change: -3)
        ChangeLabel(change: 5)
    }
}
