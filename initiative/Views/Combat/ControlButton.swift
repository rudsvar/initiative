import SwiftUI

/// A round tinted action button for the health and armor class rows. One shape
/// for every action, so the two rows read the same.
struct ControlButton: View {
    let systemImage: String
    let tint: Color
    let label: String
    var compact: Bool = false
    let action: () -> Void

    private var size: CGFloat { compact ? 30 : 38 }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(compact ? Theme.Typography.iconInline : Theme.Typography.iconAction)
                .foregroundColor(tint)
                .frame(width: size, height: size)
                .background(tint.opacity(0.16))
                .clipShape(Circle())
                .overlay(Circle().stroke(tint.opacity(0.35), lineWidth: Theme.hairline))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
