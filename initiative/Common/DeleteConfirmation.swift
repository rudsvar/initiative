import SwiftUI

extension View {
    /// Asks before deleting something the owner made. Every library and the saved
    /// sessions use it, so deleting works and reads the same everywhere.
    /// `noun` is lower case ("character", "encounter", "session").
    func deleteConfirmation<Item>(
        _ item: Binding<Item?>,
        noun: String,
        name: @escaping (Item) -> String,
        onDelete: @escaping (Item) -> Void
    ) -> some View {
        alert(
            "Delete \(noun)?",
            isPresented: Binding(get: { item.wrappedValue != nil }, set: { if !$0 { item.wrappedValue = nil } }),
            presenting: item.wrappedValue
        ) { pending in
            Button("Delete", role: .destructive) { onDelete(pending) }
            Button("Cancel", role: .cancel) {}
        } message: { pending in
            Text("\(name(pending)) will be removed. This can't be undone.")
        }
    }
}
