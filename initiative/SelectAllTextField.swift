import SwiftUI

/// A text field that selects all its existing text the moment it gains focus, so
/// tapping in to rename something (e.g. the session title) lets you immediately
/// start typing a replacement instead of having to manually clear the old value.
/// Plain SwiftUI `TextField` has no such option pre-iOS 18, hence the UIKit bridge.
struct SelectAllTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String = ""
    var font: UIFont = .preferredFont(forTextStyle: .headline)
    var textAlignment: NSTextAlignment = .center

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.delegate = context.coordinator
        field.placeholder = placeholder
        field.font = font
        field.textAlignment = textAlignment
        field.returnKeyType = .done
        field.addTarget(context.coordinator, action: #selector(Coordinator.textChanged), for: .editingChanged)
        return field
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        @objc func textChanged(_ sender: UITextField) {
            text.wrappedValue = sender.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                textField.selectAll(nil)
            }
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }
}
