import SwiftUI

struct SessionListView: View {
    let session: CombatSession
    let sessionStore: SessionStore
    @Binding var path: NavigationPath

    @State private var records: [SessionRecord] = []

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

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
                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.name)
                                    .font(.headline)
                                    .foregroundColor(Theme.textPrimary)
                                Text("\(record.combatants.count) combatants · \(record.savedAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.caption)
                                    .foregroundColor(Theme.textTertiary)
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Theme.background)
                        .swipeActions(edge: .trailing) {
                            // No extra confirmation dialog here: swipe-to-reveal + tap
                            // Delete is already two deliberate actions.
                            Button(role: .destructive) {
                                sessionStore.delete(id: record.id)
                                records = sessionStore.listSavedSessions()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Load Session")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { records = sessionStore.listSavedSessions() }
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
