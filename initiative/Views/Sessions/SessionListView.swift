import SwiftUI

struct SessionListView: View {
    let session: CombatSession
    let sessionStore: SessionStore
    @Binding var path: NavigationPath

    @State private var records: [SessionRecord] = []
    @State private var pendingDelete: SessionRecord?

    var body: some View {
        Group {
            if records.isEmpty {
                ContentUnavailableView(
                    "No Saved Sessions",
                    systemImage: "folder",
                    description: Text("Sessions save automatically as you play and appear here.")
                )
            } else {
                List {
                    ForEach(records) { record in
                        Button(action: { load(record) }) {
                            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                                Text(record.name)
                                    .font(Theme.Typography.rowTitle)
                                    .foregroundColor(Theme.textPrimary)
                                Text("\(record.combatants.count) combatants · \(record.savedAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(Theme.Typography.caption)
                                    .foregroundColor(Theme.textTertiary)
                            }
                        }
                        .buttonStyle(CardRowButtonStyle())
                        .cardRowLayout()
                        .swipeActions(edge: .trailing) {
                            // Asks first (deleteConfirmation): a session can't be got back.
                            Button(role: .destructive) {
                                pendingDelete = record
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .themedScreen()
        .navigationTitle("Load Session")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { records = sessionStore.listSavedSessions() }
        .deleteConfirmation($pendingDelete, noun: "session", name: \.name) { record in
            sessionStore.delete(id: record.id)
            records = sessionStore.listSavedSessions()
        }
    }

    private func load(_ record: SessionRecord) {
        session.load(record)
        sessionStore.setLastActiveSessionID(record.id)
        path.append(Route.combat)
    }
}

#Preview {
    NavigationStack {
        SessionListView(session: CombatSession(), sessionStore: SessionStore(), path: .constant(NavigationPath()))
    }
}
