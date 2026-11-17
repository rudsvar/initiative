import SwiftUI

extension View {
    /// Asks for an amount of temporary HP or AC. A new grant replaces the old one.
    /// `onRemove`, when given, is offered while there is something to remove.
    func temporaryGrantAlert(
        _ title: String,
        isPresented: Binding<Bool>,
        message: String,
        hasGrant: Bool,
        onGrant: @escaping (Int) -> Void,
        onRemove: (() -> Void)? = nil
    ) -> some View {
        modifier(TemporaryGrantAlert(title: title, isPresented: isPresented, message: message, hasGrant: hasGrant, onGrant: onGrant, onRemove: onRemove))
    }
}

private struct TemporaryGrantAlert: ViewModifier {
    let title: String
    @Binding var isPresented: Bool
    let message: String
    let hasGrant: Bool
    let onGrant: (Int) -> Void
    let onRemove: (() -> Void)?

    @State private var amountText = ""

    func body(content: Content) -> some View {
        content.alert(title, isPresented: $isPresented) {
            TextField("Amount", text: $amountText)
                .keyboardType(.numberPad)
            Button("Apply") {
                if let amount = Int(amountText) { onGrant(amount) }
                amountText = ""
            }
            if hasGrant, let onRemove {
                Button("Remove", role: .destructive) {
                    onRemove()
                    amountText = ""
                }
            }
            Button("Cancel", role: .cancel) { amountText = "" }
        } message: {
            Text(message)
        }
    }
}
