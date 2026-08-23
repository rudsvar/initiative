import SwiftUI

/// Read-only feed of what's happened in combat (turns, damage, heals, adds/removes).
/// Newest entries first. The underlying log is truncated automatically when
/// Previous Turn undoes a turn — see CombatSession.previousTurn().
struct LogView: View {
    let session: CombatSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if session.log.isEmpty {
                    ContentUnavailableView(
                        "No Events Yet",
                        systemImage: "list.bullet.clipboard",
                        description: Text("Actions taken during combat appear here.")
                    )
                } else {
                    List(session.log.reversed()) { entry in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.text)
                                .font(.subheadline)
                            Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle("Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    let session = CombatSession()
    session.addCombatant(name: "Goblin", initiative: 15, maxHP: 7)
    session.nextTurn()
    session.applyDamage(to: session.combatants[0].id, amount: 3)

    return LogView(session: session)
}
