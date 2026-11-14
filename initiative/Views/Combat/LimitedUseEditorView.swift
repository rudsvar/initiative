import SwiftUI

/// Names a countable resource and sets how many uses it has — Legendary
/// Actions, a "3/day" ability. A compact modal rather than a full screen: two
/// fields don't need a navigation bar, and this is created from a single tap
/// on "Add Limited Use…", so the popup should be as quick to dismiss as it was
/// to open.
struct LimitedUseEditorView: View {
    let session: CombatSession
    let combatantID: UUID
    /// nil when creating a new one.
    let existing: LimitedUse?

    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var total: Int

    init(session: CombatSession, combatantID: UUID, existing: LimitedUse?) {
        self.session = session
        self.combatantID = combatantID
        self.existing = existing
        _name = State(initialValue: existing?.name ?? "")
        _total = State(initialValue: existing?.total ?? 3)
    }

    private var isNameValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(existing == nil ? "Add Limited Use" : "Configure Limited Use")
                .font(Theme.Typography.label)
                .foregroundColor(Theme.textTertiary)

            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Name").sectionLabel()
                    TextField(text: $name) {
                        Text("e.g., Legendary Actions").foregroundColor(Theme.placeholderText)
                    }
                    .font(Theme.Typography.bodyEmphasis)
                    .foregroundColor(Theme.textPrimary)
                    .fieldStyle()
                }

                Stepper("Uses: \(total)", value: $total, in: 1...20)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.textPrimary)

                HStack(spacing: Theme.Spacing.sm) {
                    Button(existing == nil ? "Add" : "Save") { save() }
                        .font(Theme.Typography.bodyEmphasis)
                        .foregroundColor(Theme.accentForeground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(Theme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
                        .disabled(!isNameValid)
                        .opacity(isNameValid ? 1 : 0.5)

                    if let existing {
                        Button(role: .destructive) {
                            session.removeLimitedUse(existing.id, from: combatantID)
                            dismiss()
                        } label: {
                            Image(systemName: "trash")
                                .font(Theme.Typography.iconAction)
                                .foregroundColor(Theme.statusBad)
                                .frame(width: 44, height: 40)
                                .background(Theme.statusBad.opacity(0.14))
                                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
                        }
                    }
                }
            }
            .sectionCard()
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.background)
        .selfSizingSheet()
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if let existing {
            var updated = existing
            updated.name = trimmed
            updated.total = total
            session.updateLimitedUse(updated, on: combatantID)
        } else {
            session.addLimitedUse(name: trimmed, total: total, to: combatantID)
        }
        dismiss()
    }
}

#Preview {
    let session = CombatSession()
    session.addCombatant(name: "Ancient Dragon", initiative: 22)

    return Color.clear.sheet(isPresented: .constant(true)) {
        LimitedUseEditorView(session: session, combatantID: session.combatants[0].id, existing: nil)
    }
}
