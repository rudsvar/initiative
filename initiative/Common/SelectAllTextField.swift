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
    // UIKit views don't participate in SwiftUI's Theme (a plain UITextField
    // defaults to black text), so the theme color has to be passed in and
    // reapplied in updateUIView explicitly on every re-render — otherwise this
    // field silently ignores whichever palette is active.
    var textColor: Color = Theme.textPrimary
    var placeholderColor: Color = Theme.textTertiary

    func makeUIView(context: Context) -> UITextField {
        let field = UITextField()
        field.delegate = context.coordinator
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
        uiView.textColor = UIColor(textColor)
        uiView.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor(placeholderColor)]
        )
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
