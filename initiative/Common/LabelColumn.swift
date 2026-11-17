import SwiftUI

/// A row label ("Current HP", "Armor Class") in a column shared by every such label
/// on the screen, so the values after them line up. No hardcoded width: each label
/// reports its own, the screen (`sharedLabelColumn()`) keeps the widest, and all
/// size to that, so larger text or another language widens the column by itself.
struct ColumnLabel: View {
    let text: String
    @Environment(\.labelColumnWidth) private var width

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(Theme.Typography.caption)
            .foregroundColor(Theme.textTertiary)
            .fixedSize()
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(key: LabelColumnWidthKey.self, value: proxy.size.width)
                }
            )
            .frame(minWidth: width, alignment: .leading)
    }
}

private struct LabelColumnWidthKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct LabelColumnWidthEnvironmentKey: EnvironmentKey {
    static let defaultValue: CGFloat = 0
}

extension EnvironmentValues {
    fileprivate(set) var labelColumnWidth: CGFloat {
        get { self[LabelColumnWidthEnvironmentKey.self] }
        set { self[LabelColumnWidthEnvironmentKey.self] = newValue }
    }
}

private struct SharedLabelColumn: ViewModifier {
    @State private var width: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .environment(\.labelColumnWidth, width)
            .onPreferenceChange(LabelColumnWidthKey.self) { width = $0 }
    }
}

extension View {
    /// Put on the view holding `ColumnLabel`s so they share one column.
    func sharedLabelColumn() -> some View {
        modifier(SharedLabelColumn())
    }
}
