import SwiftUI

extension View {
    func borderTop(_ color: Color, width: CGFloat = 1) -> some View {
        VStack(spacing: 0) {
            Divider()
                .foregroundColor(color)
                .frame(height: width)
            self
        }
    }

    func borderBottom(_ color: Color, width: CGFloat = 1) -> some View {
        VStack(spacing: 0) {
            self
            Divider()
                .foregroundColor(color)
                .frame(height: width)
        }
    }
}
